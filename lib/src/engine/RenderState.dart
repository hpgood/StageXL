part of stagexl;

class _ContextState {
  final Matrix matrix = new Matrix.fromIdentity();
  double alpha = 1.0;
  String compositeOperation = CompositeOperation.SOURCE_OVER;

  _ContextState _nextContextState;

  _ContextState get nextContextState {
    if (_nextContextState == null) _nextContextState = new _ContextState();
    return _nextContextState;
  }
}

class RenderState {

  final CanvasRenderingContext2D _context;

  num _currentTime = 0.0;
  num _deltaTime = 0.0;
  _ContextState _firstContextState;
  _ContextState _currentContextState;

  RenderState.fromCanvasRenderingContext2D(CanvasRenderingContext2D context, [Matrix matrix]) :
    _context = context {

    _firstContextState = new _ContextState();
    _currentContextState = _firstContextState;

    if (matrix != null) {
      _firstContextState.matrix.copyFrom(matrix);
    }

    var m = _firstContextState.matrix;
    _context.setTransform(m.a, m.b, m.c, m.d, m.tx, m.ty);
    _context.globalAlpha = 1.0;
    _context.globalCompositeOperation = CompositeOperation.SOURCE_OVER;
  }

  //-------------------------------------------------------------------------------------------------
  //-------------------------------------------------------------------------------------------------

  CanvasRenderingContext2D get context => _context;
  num get currentTime => _currentTime;
  num get deltaTime => _deltaTime;

  //-------------------------------------------------------------------------------------------------

  void reset([Matrix matrix, num currentTime, num deltaTime]) {

    _currentTime = ?currentTime ? currentTime : 0.0;
    _deltaTime = ?deltaTime ? deltaTime : 0.0;
    _currentContextState = _firstContextState;

    if (matrix != null) {
      _firstContextState.matrix.copyFrom(matrix);
    }

    var m = _firstContextState.matrix;

    _context.setTransform(1.0, 0.0, 0.0, 1.0, 0.0, 0.0);
    _context.clearRect(0, 0, _context.canvas.width, _context.canvas.height);
    _context.setTransform(m.a, m.b, m.c, m.d, m.tx, m.ty);
    _context.globalAlpha = 1.0;
    _context.globalCompositeOperation = CompositeOperation.SOURCE_OVER;

  }

  //-------------------------------------------------------------------------------------------------

  void renderDisplayObject(DisplayObject displayObject) {

    var matrix = displayObject._transformationMatrix;
    var alpha = displayObject._alpha;
    var mask = displayObject._mask;
    var shadow = displayObject._shadow;
    var composite = displayObject._compositeOperation;

    var cs1 = _currentContextState as _ContextState;
    var cs2 = _currentContextState.nextContextState as _ContextState;

    _currentContextState = cs2;

    var nextMatrix = cs2.matrix;
    var nextAlpha = cs1.alpha * alpha;
    var nextCompositeOperation = (composite != null) ? composite : cs1.compositeOperation;

    nextMatrix.copyFromAndConcat(matrix, cs1.matrix);
    cs2.alpha = nextAlpha;
    cs2.compositeOperation = nextCompositeOperation;

    // apply Mask and Shadow
    if (mask != null || shadow != null) {

      _context.save();

      if (mask != null) {
        if (mask.targetSpace == null) {
          matrix = cs2.matrix;
        } else if (identical(mask.targetSpace, displayObject)) {
          matrix = cs2.matrix;
        } else if (identical(mask.targetSpace, displayObject.parent)) {
          matrix = cs1.matrix;
        } else {
          matrix = mask.targetSpace.transformationMatrixTo(displayObject);
          if (matrix == null) matrix = _identityMatrix; else matrix.concat(cs2.matrix);
        }
        mask.render(this, matrix);
      }

      if (shadow != null) {
        if (shadow.targetSpace == null) {
          matrix = cs2.matrix;
        } else if (identical(shadow.targetSpace, displayObject)) {
          matrix = cs2.matrix;
        } else if (identical(shadow.targetSpace, displayObject.parent)) {
          matrix = cs1.matrix;
        } else {
          matrix = shadow.targetSpace.transformationMatrixTo(displayObject);
          if (matrix == null) matrix = _identityMatrix; else matrix.concat(cs2.matrix);
        }
        shadow.render(this, matrix);
      }
    }

    // render DisplayObject
    var m = nextMatrix;
    _context.setTransform(m.a, m.b, m.c, m.d, m.tx, m.ty);
    _context.globalCompositeOperation = nextCompositeOperation;
    _context.globalAlpha = nextAlpha;

    if (displayObject.cached) {
      displayObject._renderCache(this);
    } else {
      displayObject.render(this);
    }

    // restore context
    if (mask != null || shadow != null) {
      _context.restore();
    }

    _currentContextState = cs1;
  }

}




