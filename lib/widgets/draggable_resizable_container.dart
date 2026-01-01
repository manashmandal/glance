import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/widget_layout.dart';

enum ResizeHandle {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  top,
  bottom,
  left,
  right,
}

class DraggableResizableContainer extends StatefulWidget {
  final Widget child;
  final bool isEditMode;
  final WidgetLayout layout;
  final Size containerSize;
  final Function(WidgetLayout) onLayoutUpdate;
  final double minWidth;
  final double minHeight;

  const DraggableResizableContainer({
    super.key,
    required this.child,
    required this.isEditMode,
    required this.layout,
    required this.containerSize,
    required this.onLayoutUpdate,
    this.minWidth = 150,
    this.minHeight = 100,
  });

  @override
  State<DraggableResizableContainer> createState() =>
      _DraggableResizableContainerState();
}

class _DraggableResizableContainerState
    extends State<DraggableResizableContainer> {
  bool _isDragging = false;
  bool _isResizing = false;
  ResizeHandle? _activeHandle;
  Offset _dragStartPosition = Offset.zero;
  WidgetLayout? _dragStartLayout;

  static const double handleSize = 12.0;
  static const double handleHitArea = 20.0;
  static const double snapIncrement = 0.02; // 2% grid for snappy feel

  double _snapToGrid(double value) {
    return (value / snapIncrement).round() * snapIncrement;
  }

  WidgetLayout _snapLayout(WidgetLayout layout) {
    return layout.copyWith(
      x: _snapToGrid(layout.x).clamp(0.0, 1.0 - layout.width),
      y: _snapToGrid(layout.y).clamp(0.0, 1.0 - layout.height),
      width: _snapToGrid(layout.width),
      height: _snapToGrid(layout.height),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main content with drag gesture
        Positioned.fill(
          child: MouseRegion(
            cursor: widget.isEditMode && !_isResizing
                ? (_isDragging
                    ? SystemMouseCursors.grabbing
                    : SystemMouseCursors.grab)
                : SystemMouseCursors.basic,
            child: GestureDetector(
              onPanStart: widget.isEditMode ? _onDragStart : null,
              onPanUpdate: widget.isEditMode ? _onDragUpdate : null,
              onPanEnd: widget.isEditMode ? _onDragEnd : null,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: widget.isEditMode
                      ? Border.all(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.7),
                          width: 2,
                        )
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),

        // Resize handles (only in edit mode)
        if (widget.isEditMode) ...[
          // Corner handles
          _buildCornerHandle(ResizeHandle.topLeft, Alignment.topLeft),
          _buildCornerHandle(ResizeHandle.topRight, Alignment.topRight),
          _buildCornerHandle(ResizeHandle.bottomLeft, Alignment.bottomLeft),
          _buildCornerHandle(ResizeHandle.bottomRight, Alignment.bottomRight),

          // Edge handles
          _buildEdgeHandle(ResizeHandle.top, Alignment.topCenter),
          _buildEdgeHandle(ResizeHandle.bottom, Alignment.bottomCenter),
          _buildEdgeHandle(ResizeHandle.left, Alignment.centerLeft),
          _buildEdgeHandle(ResizeHandle.right, Alignment.centerRight),
        ],
      ],
    );
  }

  Widget _buildCornerHandle(ResizeHandle handle, Alignment alignment) {
    return Positioned(
      left: alignment.x < 0 ? -handleSize / 2 : null,
      right: alignment.x > 0 ? -handleSize / 2 : null,
      top: alignment.y < 0 ? -handleSize / 2 : null,
      bottom: alignment.y > 0 ? -handleSize / 2 : null,
      child: MouseRegion(
        cursor: _getCursorForHandle(handle),
        child: GestureDetector(
          onPanStart: (details) => _onResizeStart(handle, details),
          onPanUpdate: _onResizeUpdate,
          onPanEnd: _onResizeEnd,
          child: Container(
            width: handleHitArea,
            height: handleHitArea,
            alignment: Alignment.center,
            child: Container(
              width: handleSize,
              height: handleSize,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEdgeHandle(ResizeHandle handle, Alignment alignment) {
    final isHorizontal =
        handle == ResizeHandle.top || handle == ResizeHandle.bottom;

    return Positioned(
      left: alignment.x == 0
          ? handleHitArea
          : (alignment.x < 0 ? -handleSize / 2 : null),
      right: alignment.x == 0
          ? handleHitArea
          : (alignment.x > 0 ? -handleSize / 2 : null),
      top: alignment.y == 0
          ? handleHitArea
          : (alignment.y < 0 ? -handleSize / 2 : null),
      bottom: alignment.y == 0
          ? handleHitArea
          : (alignment.y > 0 ? -handleSize / 2 : null),
      child: MouseRegion(
        cursor: _getCursorForHandle(handle),
        child: GestureDetector(
          onPanStart: (details) => _onResizeStart(handle, details),
          onPanUpdate: _onResizeUpdate,
          onPanEnd: _onResizeEnd,
          child: Container(
            width: isHorizontal ? null : handleHitArea,
            height: isHorizontal ? handleHitArea : null,
            alignment: Alignment.center,
            child: Container(
              width: isHorizontal ? 40 : 6,
              height: isHorizontal ? 6 : 40,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ),
    );
  }

  MouseCursor _getCursorForHandle(ResizeHandle handle) {
    switch (handle) {
      case ResizeHandle.topLeft:
      case ResizeHandle.bottomRight:
        return SystemMouseCursors.resizeUpLeftDownRight;
      case ResizeHandle.topRight:
      case ResizeHandle.bottomLeft:
        return SystemMouseCursors.resizeUpRightDownLeft;
      case ResizeHandle.top:
      case ResizeHandle.bottom:
        return SystemMouseCursors.resizeUpDown;
      case ResizeHandle.left:
      case ResizeHandle.right:
        return SystemMouseCursors.resizeLeftRight;
    }
  }

  void _onDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragStartPosition = details.globalPosition;
      _dragStartLayout = widget.layout;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || _dragStartLayout == null) return;

    final delta = details.globalPosition - _dragStartPosition;
    final deltaXPercent = delta.dx / widget.containerSize.width;
    final deltaYPercent = delta.dy / widget.containerSize.height;

    var newX = (_dragStartLayout!.x + deltaXPercent)
        .clamp(0.0, 1.0 - widget.layout.width);
    var newY = (_dragStartLayout!.y + deltaYPercent)
        .clamp(0.0, 1.0 - widget.layout.height);

    // Snap to grid for snappy feel
    newX = _snapToGrid(newX).clamp(0.0, 1.0 - widget.layout.width);
    newY = _snapToGrid(newY).clamp(0.0, 1.0 - widget.layout.height);

    widget.onLayoutUpdate(widget.layout.copyWith(x: newX, y: newY));
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _dragStartLayout = null;
    });
  }

  void _onResizeStart(ResizeHandle handle, DragStartDetails details) {
    setState(() {
      _isResizing = true;
      _activeHandle = handle;
      _dragStartPosition = details.globalPosition;
      _dragStartLayout = widget.layout;
    });
  }

  void _onResizeUpdate(DragUpdateDetails details) {
    if (!_isResizing || _dragStartLayout == null || _activeHandle == null)
      return;

    final delta = details.globalPosition - _dragStartPosition;
    final deltaXPercent = delta.dx / widget.containerSize.width;
    final deltaYPercent = delta.dy / widget.containerSize.height;

    final minWidthPercent = widget.minWidth / widget.containerSize.width;
    final minHeightPercent = widget.minHeight / widget.containerSize.height;

    var newX = _dragStartLayout!.x;
    var newY = _dragStartLayout!.y;
    var newWidth = _dragStartLayout!.width;
    var newHeight = _dragStartLayout!.height;

    switch (_activeHandle!) {
      case ResizeHandle.topLeft:
        newX = (_dragStartLayout!.x + deltaXPercent).clamp(0.0,
            _dragStartLayout!.x + _dragStartLayout!.width - minWidthPercent);
        newY = (_dragStartLayout!.y + deltaYPercent).clamp(0.0,
            _dragStartLayout!.y + _dragStartLayout!.height - minHeightPercent);
        newWidth = _dragStartLayout!.width - (newX - _dragStartLayout!.x);
        newHeight = _dragStartLayout!.height - (newY - _dragStartLayout!.y);
        break;
      case ResizeHandle.topRight:
        newY = (_dragStartLayout!.y + deltaYPercent).clamp(0.0,
            _dragStartLayout!.y + _dragStartLayout!.height - minHeightPercent);
        newWidth = (_dragStartLayout!.width + deltaXPercent)
            .clamp(minWidthPercent, 1.0 - _dragStartLayout!.x);
        newHeight = _dragStartLayout!.height - (newY - _dragStartLayout!.y);
        break;
      case ResizeHandle.bottomLeft:
        newX = (_dragStartLayout!.x + deltaXPercent).clamp(0.0,
            _dragStartLayout!.x + _dragStartLayout!.width - minWidthPercent);
        newWidth = _dragStartLayout!.width - (newX - _dragStartLayout!.x);
        newHeight = (_dragStartLayout!.height + deltaYPercent)
            .clamp(minHeightPercent, 1.0 - _dragStartLayout!.y);
        break;
      case ResizeHandle.bottomRight:
        newWidth = (_dragStartLayout!.width + deltaXPercent)
            .clamp(minWidthPercent, 1.0 - _dragStartLayout!.x);
        newHeight = (_dragStartLayout!.height + deltaYPercent)
            .clamp(minHeightPercent, 1.0 - _dragStartLayout!.y);
        break;
      case ResizeHandle.top:
        newY = (_dragStartLayout!.y + deltaYPercent).clamp(0.0,
            _dragStartLayout!.y + _dragStartLayout!.height - minHeightPercent);
        newHeight = _dragStartLayout!.height - (newY - _dragStartLayout!.y);
        break;
      case ResizeHandle.bottom:
        newHeight = (_dragStartLayout!.height + deltaYPercent)
            .clamp(minHeightPercent, 1.0 - _dragStartLayout!.y);
        break;
      case ResizeHandle.left:
        newX = (_dragStartLayout!.x + deltaXPercent).clamp(0.0,
            _dragStartLayout!.x + _dragStartLayout!.width - minWidthPercent);
        newWidth = _dragStartLayout!.width - (newX - _dragStartLayout!.x);
        break;
      case ResizeHandle.right:
        newWidth = (_dragStartLayout!.width + deltaXPercent)
            .clamp(minWidthPercent, 1.0 - _dragStartLayout!.x);
        break;
    }

    // Snap all values to grid for snappy feel
    newX = _snapToGrid(newX);
    newY = _snapToGrid(newY);
    newWidth = _snapToGrid(newWidth);
    newHeight = _snapToGrid(newHeight);

    widget.onLayoutUpdate(widget.layout.copyWith(
      x: newX,
      y: newY,
      width: newWidth,
      height: newHeight,
    ));
  }

  void _onResizeEnd(DragEndDetails details) {
    setState(() {
      _isResizing = false;
      _activeHandle = null;
      _dragStartLayout = null;
    });
  }
}
