package tusk;

import tusk.Game;
import tusk.debug.Log;
import tusk.events.*;
import tusk.modules.*;

import promhx.Deferred;
import promhx.Promise;

#if editor
import tusk.editor.Editor;
import tusk.editor.EditorEvent;
#end

#if snow
import snow.types.Types;
import snow.modules.opengl.GL;
import snow.App.AppFixedTimestep;
import snow.system.window.Window;
#else
@:dox(hide)
class Window {
    public var title:String;
    public var width:Int;
    public var height:Int;
    public var onrender:Window->Void;

    public function new() {}
}
@:dox(hide)
class Snow {
    public var window:Window;
    public function new() {
        window = new Window();
    }
}
@:dox(hide)
class AppFixedTimestep {
    public var app:Snow;
    public var alpha:Float;
    public function new() {
        alpha = 0.5;
        app = new Snow();
    }
}
@:dox(hide)
typedef AppConfig = { window:Window }
typedef ModState = Dynamic;
#end

/**
 * The main application lives here.
 *
 * It should mostly be a one-way relationship from here to children of the `Game` class
 * (width the exception of hooking up events).
 *
 * Generally responsible for showing the splash screen and emitting events.
 */
class Tusk extends AppFixedTimestep {
    public inline static var version:String = tusk.macros.Version.current();

    public static var instance:Tusk = null;

    /**
     * Sound module
     */
    public static var sound:Sound;

    /**
     * The asset manager
     */
    public static var assets:Assets;

    /**
     * The current instance of the running game!
     */
    public static var game(default, null):Game;

    /**
     * The event router
     */
    public static var router:EventRouter;

    @:noCompletion
    public function new(_game:Game) {
        super();
        router = new EventRouter();
        game = _game;
        instance = this;
    }

    @:noCompletion
    public static function routeEvent(type:EventType, handler:EventHandler) {
        router.registerHandler(type, handler);
    }

    @:noCompletion
    public static function unrouteEvent(type:EventType, handler:EventHandler) {
        router.unregisterHandler(type, handler);
    }

    @:noCompletion
    #if snow override #end function config(config:AppConfig):AppConfig {
        config.window.title = game.title;
        config.window.width = game.width;
        config.window.height = game.height;
        Log.trace("game config: " + config);
        return config;
    }

    /*private function initialize() {
    }*/

    #if editor
    public static var scenesChanged:EditorEvent = new EditorEvent();
    #end

    @:noCompletion
    #if snow override #end public function ready() {
        Log.trace("snõw is ready");

        // initialize all modules
        sound = new Sound();
        assets = new Assets();

        Log.trace("connecting rendering callback");
        app.window.onrender = render;

        #if editor
        Log.trace('setting up editor');
        Editor.init();
        #end

        Log.trace("setting up game");
        game.setup();
    }

    @:noCompletion
    #if snow override #end public function update(dt:Float) {
        router.onEvent(EventType.Update, new UpdateEvent(dt));
        #if editor
        for(inspector in tusk.editor.Editor.inspectors) {
            inspector.update();
        }
        #end
    }

    @:noCompletion
    #if snow override #end public function onkeydown(keycode:Int, scancode:Int, repeat:Bool, mod:ModState, timestamp:Float, window_id:Int) {
        router.onEvent(EventType.KeyDown, new KeyEvent(keycode, scancode, repeat, mod));
    }

    @:noCompletion
    #if snow override #end public function onkeyup(keycode:Int, scancode:Int, repeat:Bool, mod:ModState, timestamp:Float, window_id:Int) {
        router.onEvent(EventType.KeyUp, new KeyEvent(keycode, scancode, repeat, mod));
    }

    @:noCompletion
    #if snow override #end public function onmousedown(x:Int, y:Int, button:Int, timestamp:Float, window_id:Int) {
        router.onEvent(EventType.MouseDown, new MouseButtonEvent(x, y, button));
    }

    @:noCompletion
    #if snow override #end public function onmouseup(x:Int, y:Int, button:Int, timestamp:Float, window_id:Int) {
        router.onEvent(EventType.MouseUp, new MouseButtonEvent(x, y, button));
    }

    @:noCompletion
    #if snow override #end public function onmousemove(x:Int, y:Int, xrel:Int, yrel:Int, timestamp:Float, window_id:Int) {
        router.onEvent(EventType.MouseMove, new MouseMoveEvent(x, y, xrel, yrel));
    }

    private function render(window:Window) {
        router.onEvent(EventType.Render, new RenderEvent(this.alpha));
    }

    public static function pushScene(scene:Scene):Promise<Scene> {
        if(game.currentScenes.indexOf(scene) >= 0) {
            throw new tusk.debug.Exception('Scene is already running!');
        }
        game.currentScenes.push(scene);

        //scene.sceneDone = new Deferred<Scene>();
        scene.___connectRoutes();
        //router.onEvent(EventType.Load, new LoadEvent(scene));
        scene.onLoad(new LoadEvent(scene));

        #if editor
        scenesChanged.trigger();
        #end

        return scene.sceneDone.promise();
    }

    public static function removeScene(scene:Scene) {
        if(!game.currentScenes.remove(scene)) {
            return;
        }

        router.onEvent(EventType.Destroy, new DestroyEvent(scene));
        for(processor in scene.processors) {
            processor.___disconnectRoutes();
        }
        scene.___disconnectRoutes();
        for(entity in scene.entities) {
            removeEntity(entity);
        }
        if(!scene.sceneDone.isResolved()) {
            scene.sceneDone.resolve(scene);
        }

        #if editor
        scenesChanged.trigger();
        #end
    }

    /**
     * Called in an entity constructor when it is created (to route the events to the processors)
     * @param entity The entity that was just created
     */
    public static function addEntity(entity:Entity, scene:Scene) {
        // update the scene
        if(scene.entities.indexOf(entity) == -1) {
            #if editor
            scene.entitiesChanged.trigger();
            entity.componentsChanged.trigger();
            #end

            Log.trace("Added entity to scene!");
        }

        // update the processors
        for(processor in scene.processors) {
            if(processor.entities.indexOf(entity) == -1 && processor.matcher.matchesEntity(entity)) {
                processor.entities.push(entity);
                processor.onEntityChanged(entity, Entity.ChangeEvent.EntityAdded);
                Log.trace("Added entity to processor '" + Type.getClassName(Type.getClass(processor)) + "'!");
            }
        }
    }

    /**
     * Called whenever an entity changes (when its component-composition changes) (to route the events to the processors)
     * @param  entity the changed entity
     */
    public static function entityChanged(entity:Entity, event:Entity.ChangeEvent) {
        // update the processors
        for(scene in game.currentScenes) {
            for(processor in scene.processors) {
                if(processor.entities.indexOf(entity) == -1 && processor.matcher.matchesEntity(entity)) {
                    processor.entities.push(entity);
                    processor.onEntityChanged(entity, event);
                    Log.trace("Added entity to processor '" + Type.getClassName(Type.getClass(processor)) + "'!");
                }
                else if(processor.entities.indexOf(entity) != -1 && !processor.matcher.matchesEntity(entity)) {
                    processor.onEntityChanged(entity, event);
                    processor.entities.remove(entity);
                    Log.trace("Removed entity from processor '" + Type.getClassName(Type.getClass(processor)) + "'!");
                }
            }
        }
        #if editor
        entity.componentsChanged.trigger();
        #end
    }

    /**
     * Called whenever an entity is destroyed (to route the events to the processors)
     * @param  entity the destroyed entity
     */
    public static function removeEntity(entity:Entity) {
        // update the processors
        for(scene in game.currentScenes) {
            for(processor in scene.processors) {
                if(processor.entities.remove(entity)) {
                    processor.onEntityChanged(entity, Entity.ChangeEvent.EntityRemoved);
                    Log.trace("Removed entity from processor '" + Type.getClassName(Type.getClass(processor)) + "'!");
                }
            }

            // update the game
            if(scene.entities.remove(entity)) {
                #if editor
                scene.entitiesChanged.trigger();
                entity.componentsChanged.trigger();
                #end
                Log.trace("Removed entity from scene!");
            }
        }
    }

    /**
     * Creates a savegame string
     * @return a string defining the current state of the game
     */
    public static function serialize():String {
        Log.trace("Serializing game state...");
        var s = new haxe.Serializer();
        // TODO: serialize the scenes too!
        /*s.serialize(game.currentScene.processors);
        s.serialize(game.currentScene.entities);*/
        var result:String = s.toString();
        Log.trace("Serialized state:");
        Log.trace(result);
        return result;
    }
}
