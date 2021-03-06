package tusk.lib.proc;

import tusk.debug.Log;
import tusk.Matcher;
import tusk.Component;
import tusk.Processor;
import tusk.events.*;
import tusk.lib.comp.*;

import tusk.resources.Mesh;
import tusk.resources.Material;

import haxe.ds.IntMap;

import glm.Projection;
import glm.Vec4;
import glm.Mat3;
import glm.Mat4;
import glm.GLM;

#if snow
import snow.modules.opengl.GL;
#end

/**
 * Processor which fills out camera matrices for the renderer
 */
class Renderer2DProcessor extends Processor {
	private var clearColour:Vec4 = new Vec4(1.0, 1.0, 1.0, 1.0);

	public function new(?clearColour:Vec4, ?entities:Array<Entity>) {
		if(clearColour != null) this.clearColour = clearColour;
		matcher = new Matcher().include(MaterialComponent.tid).include(MeshComponent.tid).include(TransformComponent.tid);
		super(entities);
	}

	override public function onRender(event:RenderEvent) {
		// sort our entities based on depth
		// TODO: sort somewhere else that is less expensive!!
		entities.sort(function(a:Entity, b:Entity):Int {
			var ta:TransformComponent = cast a.get(TransformComponent.tid);
			var tb:TransformComponent = cast b.get(TransformComponent.tid);
			if(ta.position.z == tb.position.z) return 0;
			return ta.position.z < tb.position.z ? 1 : -1;
		});

		#if snow
		GL.disable(GL.DEPTH_TEST);
		GL.enable(GL.BLEND);
		GL.depthFunc(GL.LESS);
		GL.viewport(0, 0, Tusk.instance.app.window.width, Tusk.instance.app.window.height);
		GL.clearColor(clearColour.r, clearColour.g, clearColour.b, clearColour.a);
		GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);

		for(camera in Camera2DProcessor.cameras) {
			for(entity in entities) {
				// get our components
				var transform:TransformComponent = cast entity.get(TransformComponent.tid);
				var mesh:MeshComponent = cast entity.get(MeshComponent.tid);
				var material:MaterialComponent = cast entity.get(MaterialComponent.tid);

				if(mesh.mesh == null || mesh.vertexBuffer == null) {
					continue;
				}

				// render!
				material.material.onRender(function(mat:Material) {
					mat.setMat4("projection", camera.projectionMatrix);
					mat.setMat4("view", camera.viewMatrix);
					mat.setMat4("model", transform.modelMatrix);

					if(mat.textures != null && mat.textures.length > 0) {
						mat.setTexture("texture", 0);
					}

					if(entity.hasType(TextComponent.tid)) {
						var tc:TextComponent = cast entity.get(TextComponent.tid);
						//js.Lib.debug();
						mat.setVec4("colour", tc.colour);
					}

					if(entity.hasType(CustomUniformsComponent.tid)) {
						var customUniforms:CustomUniformsComponent = cast entity.get(CustomUniformsComponent.tid);
						customUniforms.setUniforms();
					}
				}, mesh.vertexBuffer, mesh.mesh.vertices.length);
			}
		}
		#end
	}
}