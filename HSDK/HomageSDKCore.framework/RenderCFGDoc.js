/**
 * Render JSON definition.
 */
function renderJSON() {
    var test = {
    /**
     *  The width of the rendering canvas.
     *  @type int
     */
    "width":480,
    
    /**
     *  The height of the rendering canvas.
     */
    "height":480,
    
    /**
     *  The duration, in seconds of the render.
     */
    "duration":8.5,
    
    /**
     *  The FPS of the rendering.
     */
    "fps":18,
    
    /**
     *  An array of the source layers that will be combined in the render.
     *  The list of layers starts with the background layer and ends with the one most in front.
     *  At least one layer must be provided or an error will be raised during renderer setup.
     */
    "source_layers_info":[],
    
    /**
     *  An array of outputs.
     *  At least one output must be provided or an error will be raised during setup.
     */
    "outputs_info":[]
    }
};