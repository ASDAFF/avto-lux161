/**
 * Util functions to deal with objects
 *
 * @author Viacheslav Lotsmanov
 * @author Andrew Fatkulin
 */


export has-own-prop = (ob, prop-name)-->
	Object::has-own-property.call ob, prop-name
