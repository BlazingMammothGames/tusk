package tusk;

import tusk.debug.Log;

import promhx.Promise;
import promhx.Stream;

import tusk.lib.comp.Camera2DComponent;
import tusk.lib.comp.MaterialComponent;
import tusk.lib.comp.MeshComponent;
import tusk.lib.comp.SoundComponent;
import tusk.lib.comp.SplashScreen_ShakeComponent;
import tusk.lib.comp.TransformComponent;
import tusk.lib.proc.Camera2DProcessor;
import tusk.lib.proc.MaterialProcessor;
import tusk.lib.proc.MeshProcessor;
import tusk.lib.proc.Renderer2DProcessor;
import tusk.lib.proc.SplashScreen_RoarShakeProcessor;
import tusk.lib.proc.TransformProcessor;

import tusk.resources.Mesh;
import tusk.resources.Material;
import tusk.resources.Font;
import tusk.resources.Texture;
import tusk.resources.Sound;

import glm.Vec2;
import glm.Vec3;
import glm.Vec4;
import glm.Quat;

class SplashScreen extends Scene {
	public function new() { super(); }

	override public function onLoad(_) {
		Log.info("Loading splash screen..");

		// load the resources
		Promise.when(
			tusk.defaults.Primitives.loadQuad(),
			tusk.defaults.Materials.loadUnlitTextured(),
			tusk.defaults.Fonts.loadSubatomic_Screen(),
			Tusk.assets.loadTexture('blazingmammothgames.png', haxe.Resource.getBytes('blazingmammothgames.png')),
			Tusk.assets.loadSound('assets/sounds/blazingmammothgames.ogg')
		).then(function(quad:Mesh, mat:Material, font:Font, logo:Texture, roar:Sound) {
			// set the material's texture
			mat.textures = new Array<Texture>();
			mat.textures.push(logo);

			// load processors
			this.useProcessor(new SplashScreen_RoarShakeProcessor(function() {
					sceneDone.resolve(null);
			}));
			this.useProcessor(new tusk.lib.proc.SoundProcessor());
			this.useProcessor(new MeshProcessor());
			this.useProcessor(new MaterialProcessor());
			this.useProcessor(new Camera2DProcessor());
			this.useProcessor(new TransformProcessor());
			this.useProcessor(new Renderer2DProcessor(new Vec4(1.0, 1.0, 1.0, 1.0)));

			// create the camera
			var w:Float = Tusk.instance.app.window.width;
			var h:Float = Tusk.instance.app.window.height;
			entities.push(new Entity([
				new TransformComponent(),
				new Camera2DComponent(new Vec2(w, h) / -2.0, new Vec2(w, h) / 2.0, -100, 100)
			]));

			// create the logo
			var sc:SoundComponent = new SoundComponent(roar.path);
			sc.play = true;
			entities.push(new Entity([
				new TransformComponent(new Vec3(), Quat.identity(), new Vec3(256, 256, 256)),
				new MeshComponent(quad.path),
				new MaterialComponent(mat.path),
				new SplashScreen_ShakeComponent(),
				sc
			]));

			// tell the processors we've started
			Tusk.router.onEvent(tusk.events.EventType.Start);
		});
	}
}