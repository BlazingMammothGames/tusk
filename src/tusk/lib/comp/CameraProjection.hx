package tusk.lib.comp;

import tusk.Component;
import tusk.math.Matrix4x4;

/**
 * A tŭsk standard libary component for defining a camera projection matrix
 */
class CameraProjection extends Component {
	/**
	 * The computed projection matrix
	 */
	var projectionMatrix:Matrix4x4;

	/**
	 * Whether the projection matrix is dirt and needs to be recalculated or not
	 */
	var dirty:Bool;
}