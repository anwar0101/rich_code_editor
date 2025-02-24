// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide materialTextSelectionControls;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide TextSelectionControls;
import 'package:rich_code_editor/code_editor/code_highlighter.dart';
import 'package:rich_code_editor/code_editor/widgets/code_selection.dart' as cs;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:rich_code_editor/code_editor/widgets/code_editable.dart' as ce;
import 'package:rich_code_editor/code_editor/widgets/material_selection.dart' as ms;

import 'code_editable_text.dart';
import 'code_editing_value.dart';

export 'package:flutter/services.dart' show TextInputType, TextInputAction, TextCapitalization;

/// Signature for the [CodeTextField.buildCounter] callback.
typedef InputCounterWidgetBuilder = Widget Function(
  /// The build context for the CodeTextField
  BuildContext context, {

  /// The length of the string currently in the input.
  @required int currentLength,

  /// The maximum string length that can be entered into the CodeTextField.
  @required int maxLength,

  /// Whether or not the CodeTextField is currently focused.  Mainly provided for
  /// the [liveRegion] parameter in the [Semantics] widget for accessibility.
  @required bool isFocused,
});

/// A material design text field.
///
/// A text field lets the user enter text, either with hardware keyboard or with
/// an onscreen keyboard.
///
/// The text field calls the [onChanged] callback whenever the user changes the
/// text in the field. If the user indicates that they are done typing in the
/// field (e.g., by pressing a button on the soft keyboard), the text field
/// calls the [onSubmitted] callback.
///
/// To control the text that is displayed in the text field, use the
/// [controller]. For example, to set the initial value of the text field, use
/// a [controller] that already contains some text. The [controller] can also
/// control the selection and composing region (and to observe changes to the
/// text, selection, and composing region).
///
/// By default, a text field has a [decoration] that draws a divider below the
/// text field. You can use the [decoration] property to control the decoration,
/// for example by adding a label or an icon. If you set the [decoration]
/// property to null, the decoration will be removed entirely, including the
/// extra padding introduced by the decoration to save space for the labels.
///
/// If [decoration] is non-null (which is the default), the text field requires
/// one of its ancestors to be a [Material] widget. When the [CodeTextField] is
/// tapped an ink splash that paints on the material is triggered, see
/// [ThemeData.splashFactory].
///
/// To integrate the [CodeTextField] into a [Form] with other [FormField] widgets,
/// consider using [TextFormField].
///
/// Remember to [dispose] of the [CodeEditingController] when it is no longer needed.
/// This will ensure we discard any resources used by the object.
///
/// {@tool sample}
/// This example shows how to create a [CodeTextField] that will obscure input. The
/// [InputDecoration] surrounds the field in a border using [OutlineInputBorder]
/// and adds a label.
///
/// ```dart
/// CodeTextField(
///   obscureText: true,
///   decoration: InputDecoration(
///     border: OutlineInputBorder(),
///     labelText: 'Password',
///   ),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * <https://material.io/design/components/text-fields.html>
///  * [TextFormField], which integrates with the [Form] widget.
///  * [InputDecorator], which shows the labels and other visual elements that
///    surround the actual text editing widget.
///  * [CodeEditableText], which is the raw text editing control at the heart of a
///    [CodeTextField]. The [CodeEditableText] widget is rarely used directly unless
///    you are implementing an entirely different design language, such as
///    Cupertino.
///  * Learn how to use a [CodeEditingController] in one of our [cookbook recipe]s.(https://flutter.dev/docs/cookbook/forms/text-field-changes#2-use-a-CodeEditingController)
class CodeTextField extends StatefulWidget {
  /// Creates a Material Design text field.
  ///
  /// If [decoration] is non-null (which is the default), the text field requires
  /// one of its ancestors to be a [Material] widget.
  ///
  /// To remove the decoration entirely (including the extra padding introduced
  /// by the decoration to save space for the labels), set the [decoration] to
  /// null.
  ///
  /// The [maxLines] property can be set to null to remove the restriction on
  /// the number of lines. By default, it is one, meaning this is a single-line
  /// text field. [maxLines] must not be zero.
  ///
  /// The [maxLength] property is set to null by default, which means the
  /// number of characters allowed in the text field is not restricted. If
  /// [maxLength] is set a character counter will be displayed below the
  /// field showing how many characters have been entered. If the value is
  /// set to a positive integer it will also display the maximum allowed
  /// number of characters to be entered.  If the value is set to
  /// [CodeTextField.noMaxLength] then only the current length is displayed.
  ///
  /// After [maxLength] characters have been input, additional input
  /// is ignored, unless [maxLengthEnforced] is set to false. The text field
  /// enforces the length with a [LengthLimitingTextInputFormatter], which is
  /// evaluated after the supplied [inputFormatters], if any. The [maxLength]
  /// value must be either null or greater than zero.
  ///
  /// If [maxLengthEnforced] is set to false, then more than [maxLength]
  /// characters may be entered, and the error counter and divider will
  /// switch to the [decoration.errorStyle] when the limit is exceeded.
  ///
  /// The text cursor is not shown if [showCursor] is false or if [showCursor]
  /// is null (the default) and [readOnly] is true.
  ///
  /// The [textAlign], [autofocus], [obscureText], [readOnly], [autocorrect],
  /// [maxLengthEnforced], [scrollPadding], [maxLines], and [maxLength]
  /// arguments must not be null.
  ///
  /// See also:
  ///
  ///  * [maxLength], which discusses the precise meaning of "number of
  ///    characters" and how it may differ from the intuitive meaning.
  const CodeTextField({
    Key key,
    this.controller,
    this.focusNode,
    this.decoration = const InputDecoration(),
    TextInputType keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.textDirection,
    this.readOnly = false,
    this.showCursor,
    this.autofocus = false,
    this.autocorrect = true,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.maxLengthEnforced = true,
    this.hideKeyboardUntilTapped = false,
    this.onChanged,
    this.onBackSpacePress,
    this.onEnterPress,
    this.onPasteAction,
    this.onEditingComplete,
    this.onSubmitted,
    this.onRectChanged,
    this.inputFormatters,
    this.enabled,
    this.cursorWidth = 2.0,
    this.cursorRadius,
    this.cursorColor,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.dragStartBehavior = DragStartBehavior.start,
    this.enableInteractiveSelection,
    this.onTap,
    this.buildCounter,
    this.scrollController,
    this.scrollPhysics,
    @required this.highlighter,
  })  : assert(textAlign != null),
        assert(readOnly != null),
        assert(autofocus != null),
        assert(autocorrect != null),
        assert(maxLengthEnforced != null),
        assert(scrollPadding != null),
        assert(dragStartBehavior != null),
        assert(maxLines == null || maxLines > 0),
        assert(minLines == null || minLines > 0),
        assert(highlighter != null),
        assert(
          (maxLines == null) || (minLines == null) || (maxLines >= minLines),
          'minLines can\'t be greater than maxLines',
        ),
        assert(expands != null),
        assert(
          !expands || (maxLines == null && minLines == null),
          'minLines and maxLines must be null when expands is true.',
        ),
        assert(maxLength == null ||
            maxLength == CodeTextField.noMaxLength ||
            maxLength > 0),
        keyboardType = keyboardType ??
            (maxLines == 1 ? TextInputType.text : TextInputType.multiline),
        super(key: key);

  /// Controls the text being edited.
  ///
  /// If null, this widget will create its own [CodeEditingController].
  final CodeEditingController controller;

  /// Defines the keyboard focus for this widget.
  ///
  /// The [focusNode] is a long-lived object that's typically managed by a
  /// [StatefulWidget] parent. See [FocusNode] for more information.
  ///
  /// To give the keyboard focus to this widget, provide a [focusNode] and then
  /// use the current [FocusScope] to request the focus:
  ///
  /// ```dart
  /// FocusScope.of(context).requestFocus(myFocusNode);
  /// ```
  ///
  /// This happens automatically when the widget is tapped.
  ///
  /// To be notified when the widget gains or loses the focus, add a listener
  /// to the [focusNode]:
  ///
  /// ```dart
  /// focusNode.addListener(() { print(myFocusNode.hasFocus); });
  /// ```
  ///
  /// If null, this widget will create its own [FocusNode].
  ///
  /// ## Keyboard
  ///
  /// Requesting the focus will typically cause the keyboard to be shown
  /// if it's not showing already.
  ///
  /// On Android, the user can hide the keyboard - without changing the focus -
  /// with the system back button. They can restore the keyboard's visibility
  /// by tapping on a text field.  The user might hide the keyboard and
  /// switch to a physical keyboard, or they might just need to get it
  /// out of the way for a moment, to expose something it's
  /// obscuring. In this case requesting the focus again will not
  /// cause the focus to change, and will not make the keyboard visible.
  ///
  /// This widget builds an [CodeEditableText] and will ensure that the keyboard is
  /// showing when it is tapped by calling [CodeEditableTextState.requestKeyboard()].
  final FocusNode focusNode;

  /// The decoration to show around the text field.
  ///
  /// By default, draws a horizontal line under the text field but can be
  /// configured to show an icon, label, hint text, and error text.
  ///
  /// Specify null to remove the decoration entirely (including the
  /// extra padding introduced by the decoration to save space for the labels).
  final InputDecoration decoration;

  /// {@macro flutter.widgets.CodeEditableText.keyboardType}
  final TextInputType keyboardType;

  /// The type of action button to use for the keyboard.
  ///
  /// Defaults to [TextInputAction.newline] if [keyboardType] is
  /// [TextInputType.multiline] and [TextInputAction.done] otherwise.
  final TextInputAction textInputAction;

  /// {@macro flutter.widgets.CodeEditableText.textCapitalization}
  final TextCapitalization textCapitalization;

  /// The style to use for the text being edited.
  ///
  /// This text style is also used as the base style for the [decoration].
  ///
  /// If null, defaults to the `subhead` text style from the current [Theme].
  final TextStyle style;

  /// {@macro flutter.widgets.CodeEditableText.strutStyle}
  final StrutStyle strutStyle;

  /// {@macro flutter.widgets.CodeEditableText.textAlign}
  final TextAlign textAlign;

  /// {@macro flutter.material.inputDecorator.textAlignVertical}
  final TextAlignVertical textAlignVertical;

  /// {@macro flutter.widgets.CodeEditableText.textDirection}
  final TextDirection textDirection;

  /// {@macro flutter.widgets.CodeEditableText.autofocus}
  final bool autofocus;

  /// {@macro flutter.widgets.CodeEditableText.autocorrect}
  final bool autocorrect;

  /// {@macro flutter.widgets.CodeEditableText.maxLines}
  final int maxLines;

  /// {@macro flutter.widgets.CodeEditableText.minLines}
  final int minLines;

  /// {@macro flutter.widgets.CodeEditableText.expands}
  final bool expands;

  /// {@macro flutter.widgets.CodeEditableText.readOnly}
  final bool readOnly;

  /// Code Highlighter
  final CodeEditingValueHighlighterBase highlighter;

  /// {@macro flutter.widgets.CodeEditableText.showCursor}
  final bool showCursor;

  /// If [maxLength] is set to this value, only the "current input length"
  /// part of the character counter is shown.
  static const int noMaxLength = -1;

  /// The maximum number of characters (Unicode scalar values) to allow in the
  /// text field.
  ///
  /// If set, a character counter will be displayed below the
  /// field showing how many characters have been entered. If set to a number
  /// greater than 0, it will also display the maximum number allowed. If set
  /// to [CodeTextField.noMaxLength] then only the current character count is displayed.
  ///
  /// After [maxLength] characters have been input, additional input
  /// is ignored, unless [maxLengthEnforced] is set to false. The text field
  /// enforces the length with a [LengthLimitingTextInputFormatter], which is
  /// evaluated after the supplied [inputFormatters], if any.
  ///
  /// This value must be either null, [CodeTextField.noMaxLength], or greater than 0.
  /// If null (the default) then there is no limit to the number of characters
  /// that can be entered. If set to [CodeTextField.noMaxLength], then no limit will
  /// be enforced, but the number of characters entered will still be displayed.
  ///
  /// Whitespace characters (e.g. newline, space, tab) are included in the
  /// character count.
  ///
  /// If [maxLengthEnforced] is set to false, then more than [maxLength]
  /// characters may be entered, but the error counter and divider will
  /// switch to the [decoration.errorStyle] when the limit is exceeded.
  ///
  /// ## Limitations
  ///
  /// The text field does not currently count Unicode grapheme clusters (i.e.
  /// characters visible to the user), it counts Unicode scalar values, which
  /// leaves out a number of useful possible characters (like many emoji and
  /// composed characters), so this will be inaccurate in the presence of those
  /// characters. If you expect to encounter these kinds of characters, be
  /// generous in the maxLength used.
  ///
  /// For instance, the character "ö" can be represented as '\u{006F}\u{0308}',
  /// which is the letter "o" followed by a composed diaeresis "¨", or it can
  /// be represented as '\u{00F6}', which is the Unicode scalar value "LATIN
  /// SMALL LETTER O WITH DIAERESIS". In the first case, the text field will
  /// count two characters, and the second case will be counted as one
  /// character, even though the user can see no difference in the input.
  ///
  /// Similarly, some emoji are represented by multiple scalar values. The
  /// Unicode "THUMBS UP SIGN + MEDIUM SKIN TONE MODIFIER", "👍🏽", should be
  /// counted as a single character, but because it is a combination of two
  /// Unicode scalar values, '\u{1F44D}\u{1F3FD}', it is counted as two
  /// characters.
  ///
  /// See also:
  ///
  ///  * [LengthLimitingTextInputFormatter] for more information on how it
  ///    counts characters, and how it may differ from the intuitive meaning.
  final int maxLength;

  /// If true, prevents the field from allowing more than [maxLength]
  /// characters.
  ///
  /// If [maxLength] is set, [maxLengthEnforced] indicates whether or not to
  /// enforce the limit, or merely provide a character counter and warning when
  /// [maxLength] is exceeded.
  final bool maxLengthEnforced;

  /// If this value is false, we do not show keyboard on the first load.
  /// Only after a tap, the keyboard will become.
  /// So the widget will display a cursor but not the keyboard
  final bool hideKeyboardUntilTapped;

  /// {@macro flutter.widgets.CodeEditableText.onChanged}
  ///
  /// See also:
  ///
  ///  * [inputFormatters], which are called before [onChanged]
  ///    runs and can validate and change ("format") the input value.
  ///  * [onEditingComplete], [onSubmitted], [onSelectionChanged]:
  ///    which are more specialized input change notifications.
  final ValueChanged<String> onChanged;

  // Trigger when backspace was pressed with value before backspace was pressed
  final ValueChanged<CodeEditingValue> onBackSpacePress;

  // Trigger when enter was pressed with value before enter was pressed
  final ValueChanged<CodeEditingValue> onEnterPress;

  /// Triggers after after paste action was performed on editor.
  /// Use this callback to update line numbers if required.
  final ValueChanged<CodeEditingValue> onPasteAction;

  /// {@macro flutter.widgets.CodeEditableText.onEditingComplete}
  final VoidCallback onEditingComplete;

  /// {@macro flutter.widgets.CodeEditableText.onSubmitted}
  final ValueChanged<String> onSubmitted;

  final ValueChanged<Rect> onRectChanged;

  /// {@macro flutter.widgets.CodeEditableText.inputFormatters}
  final List<TextInputFormatter> inputFormatters;

  /// If false the text field is "disabled": it ignores taps and its
  /// [decoration] is rendered in grey.
  ///
  /// If non-null this property overrides the [decoration]'s
  /// [Decoration.enabled] property.
  final bool enabled;

  /// {@macro flutter.widgets.CodeEditableText.cursorWidth}
  final double cursorWidth;

  /// {@macro flutter.widgets.CodeEditableText.cursorRadius}
  final Radius cursorRadius;

  /// The color to use when painting the cursor.
  ///
  /// Defaults to the theme's `cursorColor` when null.
  final Color cursorColor;

  /// The appearance of the keyboard.
  ///
  /// This setting is only honored on iOS devices.
  ///
  /// If unset, defaults to the brightness of [ThemeData.primaryColorBrightness].
  final Brightness keyboardAppearance;

  /// {@macro flutter.widgets.CodeEditableText.scrollPadding}
  final EdgeInsets scrollPadding;

  /// {@macro flutter.widgets.CodeEditableText.enableInteractiveSelection}
  final bool enableInteractiveSelection;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// {@macro flutter.rendering.editable.selectionEnabled}
  bool get selectionEnabled {
    return enableInteractiveSelection ?? true;
  }

  /// Called when the user taps on this text field.
  ///
  /// The text field builds a [GestureDetector] to handle input events like tap,
  /// to trigger focus requests, to move the caret, adjust the selection, etc.
  /// Handling some of those events by wrapping the text field with a competing
  /// GestureDetector is problematic.
  ///
  /// To unconditionally handle taps, without interfering with the text field's
  /// internal gesture detector, provide this callback.
  ///
  /// If the text field is created with [enabled] false, taps will not be
  /// recognized.
  ///
  /// To be notified when the text field gains or loses the focus, provide a
  /// [focusNode] and add a listener to that.
  ///
  /// To listen to arbitrary pointer events without competing with the
  /// text field's internal gesture detector, use a [Listener].
  final GestureTapCallback onTap;

  /// Callback that generates a custom [InputDecorator.counter] widget.
  ///
  /// See [InputCounterWidgetBuilder] for an explanation of the passed in
  /// arguments.  The returned widget will be placed below the line in place of
  /// the default widget built when [counterText] is specified.
  ///
  /// The returned widget will be wrapped in a [Semantics] widget for
  /// accessibility, but it also needs to be accessible itself.  For example,
  /// if returning a Text widget, set the [semanticsLabel] property.
  ///
  /// {@tool sample}
  /// ```dart
  /// Widget counter(
  ///   BuildContext context,
  ///   {
  ///     int currentLength,
  ///     int maxLength,
  ///     bool isFocused,
  ///   }
  /// ) {
  ///   return Text(
  ///     '$currentLength of $maxLength characters',
  ///     semanticsLabel: 'character count',
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  final InputCounterWidgetBuilder buildCounter;

  /// {@macro flutter.widgets.edtiableText.scrollPhysics}
  final ScrollPhysics scrollPhysics;

  /// {@macro flutter.widgets.CodeEditableText.scrollController}
  final ScrollController scrollController;

  @override
  CodeTextFieldState createState() => CodeTextFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CodeEditingController>(
        'controller', controller,
        defaultValue: null));
    properties.add(DiagnosticsProperty<FocusNode>('focusNode', focusNode,
        defaultValue: null));
    properties
        .add(DiagnosticsProperty<bool>('enabled', enabled, defaultValue: null));
    properties.add(DiagnosticsProperty<InputDecoration>(
        'decoration', decoration,
        defaultValue: const InputDecoration()));
    properties.add(DiagnosticsProperty<TextInputType>(
        'keyboardType', keyboardType,
        defaultValue: TextInputType.text));
    properties.add(
        DiagnosticsProperty<TextStyle>('style', style, defaultValue: null));
    properties.add(
        DiagnosticsProperty<bool>('autofocus', autofocus, defaultValue: false));
    properties.add(DiagnosticsProperty<bool>('autocorrect', autocorrect,
        defaultValue: true));
    properties.add(IntProperty('maxLines', maxLines, defaultValue: 1));
    properties.add(IntProperty('minLines', minLines, defaultValue: null));
    properties.add(
        DiagnosticsProperty<bool>('expands', expands, defaultValue: false));
    properties.add(IntProperty('maxLength', maxLength, defaultValue: null));
    properties.add(FlagProperty('maxLengthEnforced',
        value: maxLengthEnforced,
        defaultValue: true,
        ifFalse: 'maxLength not enforced'));
    properties.add(EnumProperty<TextInputAction>(
        'textInputAction', textInputAction,
        defaultValue: null));
    properties.add(EnumProperty<TextCapitalization>(
        'textCapitalization', textCapitalization,
        defaultValue: TextCapitalization.none));
    properties.add(EnumProperty<TextAlign>('textAlign', textAlign,
        defaultValue: TextAlign.start));
    properties.add(DiagnosticsProperty<TextAlignVertical>(
        'textAlignVertical', textAlignVertical,
        defaultValue: null));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
    properties
        .add(DoubleProperty('cursorWidth', cursorWidth, defaultValue: 2.0));
    properties.add(DiagnosticsProperty<Radius>('cursorRadius', cursorRadius,
        defaultValue: null));
    properties
        .add(ColorProperty('cursorColor', cursorColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Brightness>(
        'keyboardAppearance', keyboardAppearance,
        defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>(
        'scrollPadding', scrollPadding,
        defaultValue: const EdgeInsets.all(20.0)));
    properties.add(FlagProperty('selectionEnabled',
        value: selectionEnabled,
        defaultValue: true,
        ifFalse: 'selection disabled'));
    properties.add(DiagnosticsProperty<ScrollController>(
        'scrollController', scrollController,
        defaultValue: null));
    properties.add(DiagnosticsProperty<ScrollPhysics>(
        'scrollPhysics', scrollPhysics,
        defaultValue: null));
  }
}

class CodeTextFieldState extends State<CodeTextField>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<CodeEditableTextState> _codeEditableTextKey =
      GlobalKey<CodeEditableTextState>();

  Set<InteractiveInkFeature> _splashes;
  InteractiveInkFeature _currentSplash;

  CodeEditingController _controller;
  CodeEditingController get _effectiveController =>
      widget.controller ?? _controller;

  FocusNode _focusNode;
  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_focusNode ??= FocusNode());

  bool _isHovering = false;

  bool _showKeyboard = false;

  bool get needsCounter =>
      widget.maxLength != null &&
      widget.decoration != null &&
      widget.decoration.counterText == null;

  bool _shouldShowSelectionToolbar = true;

  bool _showSelectionHandles = false;

  InputDecoration _getEffectiveDecoration() {
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final ThemeData themeData = Theme.of(context);
    final InputDecoration effectiveDecoration =
        (widget.decoration ?? const InputDecoration())
            .applyDefaults(themeData.inputDecorationTheme)
            .copyWith(
              enabled: widget.enabled,
              hintMaxLines: widget.decoration?.hintMaxLines ?? widget.maxLines,
            );

    // No need to build anything if counter or counterText were given directly.
    if (effectiveDecoration.counter != null ||
        effectiveDecoration.counterText != null) return effectiveDecoration;

    // If buildCounter was provided, use it to generate a counter widget.
    Widget counter;
    final int currentLength = _effectiveController.value.text.runes.length;
    if (effectiveDecoration.counter == null &&
        effectiveDecoration.counterText == null &&
        widget.buildCounter != null) {
      final bool isFocused = _effectiveFocusNode.hasFocus;
      counter = Semantics(
        container: true,
        liveRegion: isFocused,
        child: widget.buildCounter(
          context,
          currentLength: currentLength,
          maxLength: widget.maxLength,
          isFocused: isFocused,
        ),
      );
      return effectiveDecoration.copyWith(counter: counter);
    }

    if (widget.maxLength == null)
      return effectiveDecoration; // No counter widget
  }

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) _controller = CodeEditingController();
  }

  @override
  void didUpdateWidget(CodeTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && oldWidget.controller != null)
      _controller = CodeEditingController.fromValue(oldWidget.controller.value);
    else if (widget.controller != null && oldWidget.controller == null)
      _controller = null;
    final bool isEnabled = widget.enabled ?? widget.decoration?.enabled ?? true;
    final bool wasEnabled =
        oldWidget.enabled ?? oldWidget.decoration?.enabled ?? true;
    if (wasEnabled && !isEnabled) {
      _effectiveFocusNode.unfocus();
    }
    if (_effectiveFocusNode.hasFocus && widget.readOnly != oldWidget.readOnly) {
      if (_effectiveController.selection.isCollapsed) {
        _showSelectionHandles = !widget.readOnly;
      }
    }
  }

  @override
  void dispose() {
    _focusNode?.dispose();
    super.dispose();
  }

  CodeEditableTextState get _codeEditableText =>
      _codeEditableTextKey.currentState;

  void _requestKeyboard() {
    _codeEditableText?.requestKeyboard();
  }

  bool _shouldShowSelectionHandles(ce.SelectionChangedCause cause) {
    // When the text field is activated by something that doesn't trigger the
    // selection overlay, we shouldn't show the handles either.
    if (!_shouldShowSelectionToolbar) return false;

    if (cause == SelectionChangedCause.keyboard) return false;

    if (widget.readOnly && _effectiveController.selection.isCollapsed)
      return false;

    if (cause == SelectionChangedCause.longPress) return true;

    if (_effectiveController.textSpan.text.isNotEmpty) return true;

    return false;
  }

  void _handleSelectionChanged(
      TextSelection selection, ce.SelectionChangedCause cause) {
    final bool willShowSelectionHandles = _shouldShowSelectionHandles(cause);
    if (willShowSelectionHandles != _showSelectionHandles) {
      setState(() {
        _showSelectionHandles = willShowSelectionHandles;
      });
    }

    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
        if (cause == SelectionChangedCause.longPress) {
          _codeEditableText?.bringIntoView(selection.base);
        }
        return;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      // Do nothing.
    }
  }

  /// Toggle the toolbar when a selection handle is tapped.
  void _handleSelectionHandleTapped() {
    if (_effectiveController.selection.isCollapsed) {
      _codeEditableText.toggleToolbar();
    }
  }

  ce.RenderEditableCode get _renderEditable =>
      _codeEditableTextKey.currentState.renderEditable;

  void _handleTapDown(TapDownDetails details) {
    _renderEditable.handleTapDown(details);

    // The selection overlay should only be shown when the user is interacting
    // through a touch screen (via either a finger or a stylus). A mouse shouldn't
    // trigger the selection overlay.
    // For backwards-compatibility, we treat a null kind the same as touch.
    final PointerDeviceKind kind = details.kind;
    _shouldShowSelectionToolbar = kind == null ||
        kind == PointerDeviceKind.touch ||
        kind == PointerDeviceKind.stylus;
  }

  void _handleForcePressStarted(ForcePressDetails details) {
    if (widget.selectionEnabled) {
      _renderEditable.selectWordsInRange(
        from: details.globalPosition,
        cause: ce.SelectionChangedCause.forcePress,
      );
      if (_shouldShowSelectionToolbar) {
        _codeEditableTextKey.currentState.showToolbar();
      }
    }
  }

  void _handleSingleTapUp(TapUpDetails details) {
    _codeEditableText?.enableShowKeyboard();
    _codeEditableText?.hideToolbar(); //ensure toolbar is hidden if there was initially created
    if (widget.selectionEnabled) {
      switch (Theme.of(context).platform) {
        case TargetPlatform.iOS:
          _renderEditable.selectWordEdge(cause: ce.SelectionChangedCause.tap);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
          _renderEditable.selectPosition(cause: ce.SelectionChangedCause.tap);
          break;
      }
    }
    _requestKeyboard();
    if (widget.onTap != null) widget.onTap();
  }

  void _handleSingleTapCancel() {
  }

  void _handleSingleLongTapStart(LongPressStartDetails details) {
    if (widget.selectionEnabled) {
      switch (Theme.of(context).platform) {
        case TargetPlatform.iOS:
          _renderEditable.selectPositionAt(
            from: details.globalPosition,
            cause: ce.SelectionChangedCause.longPress,
          );
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
          _renderEditable.selectWord(cause: ce.SelectionChangedCause.longPress);
          Feedback.forLongPress(context);
          break;
      }
    }
  }

  void _handleSingleLongTapMoveUpdate(LongPressMoveUpdateDetails details) {
    if (widget.selectionEnabled) {
      switch (Theme.of(context).platform) {
        case TargetPlatform.iOS:
          _renderEditable.selectPositionAt(
            from: details.globalPosition,
            cause: ce.SelectionChangedCause.longPress,
          );
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
          _renderEditable.selectWordsInRange(
            from: details.globalPosition - details.offsetFromOrigin,
            to: details.globalPosition,
            cause: ce.SelectionChangedCause.longPress,
          );
          break;
      }
    }
  }

  void _handleSingleLongTapEnd(LongPressEndDetails details) {
    if (widget.selectionEnabled) {
      if (_shouldShowSelectionToolbar)
        _codeEditableTextKey.currentState.showToolbar();
    }
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    if (widget.selectionEnabled) {
      _renderEditable.selectWord(cause: ce.SelectionChangedCause.doubleTap);
      if (_shouldShowSelectionToolbar) {
        _codeEditableText.showToolbar();
      }
    }
  }

  void _handleMouseDragSelectionStart(DragStartDetails details) {
    _renderEditable.selectPositionAt(
      from: details.globalPosition,
      cause: ce.SelectionChangedCause.drag,
    );
  }

  void _handleMouseDragSelectionUpdate(
    DragStartDetails startDetails,
    DragUpdateDetails updateDetails,
  ) {
    _renderEditable.selectPositionAt(
      from: startDetails.globalPosition,
      to: updateDetails.globalPosition,
      cause: ce.SelectionChangedCause.drag,
    );
  }

  @override
  bool get wantKeepAlive => _splashes != null && _splashes.isNotEmpty;

  @override
  void deactivate() {
    if (_splashes != null) {
      final Set<InteractiveInkFeature> splashes = _splashes;
      _splashes = null;
      for (InteractiveInkFeature splash in splashes) splash.dispose();
      _currentSplash = null;
    }
    assert(_currentSplash == null);
    super.deactivate();
  }

  void _handlePointerEnter(PointerEnterEvent event) => _handleHover(true);
  void _handlePointerExit(PointerExitEvent event) => _handleHover(false);

  void _handleHover(bool hovering) {
    if (hovering != _isHovering) {
      setState(() {
        return _isHovering = hovering;
      });
    }
  }

  _pasteHandler() {
    this._codeEditableText.pendingPasteUpdate = true;
  }

  _toTextEditingValue(CodeEditingValue codeEditingValue) {
    return TextEditingValue(
        text: codeEditingValue.text,
        composing: codeEditingValue.composing,
        selection: codeEditingValue.selection);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    assert(debugCheckHasMaterial(context));
    // TODO(jonahwilliams): uncomment out this check once we have migrated tests.
    // assert(debugCheckHasMaterialLocalizations(context));
    assert(debugCheckHasDirectionality(context));
    assert(
      !(widget.style != null &&
          widget.style.inherit == false &&
          (widget.style.fontSize == null || widget.style.textBaseline == null)),
      'inherit false style must supply fontSize and textBaseline',
    );

    final ThemeData themeData = Theme.of(context);
    final TextStyle style = themeData.textTheme.subhead.merge(widget.style);
    final Brightness keyboardAppearance =
        widget.keyboardAppearance ?? themeData.primaryColorBrightness;
    final CodeEditingController controller = _effectiveController;
    final FocusNode focusNode = _effectiveFocusNode;
    final List<TextInputFormatter> formatters =
        widget.inputFormatters ?? <TextInputFormatter>[];
    if (widget.maxLength != null && widget.maxLengthEnforced)
      formatters.add(LengthLimitingTextInputFormatter(widget.maxLength));

    bool forcePressEnabled;
    cs.TextSelectionControls textSelectionControls;
    bool paintCursorAboveText;
    bool cursorOpacityAnimates;
    Offset cursorOffset;
    Color cursorColor = widget.cursorColor;
    Radius cursorRadius = widget.cursorRadius;

    switch (themeData.platform) {
      case TargetPlatform.iOS:
        forcePressEnabled = true;
        textSelectionControls = textSelectionControls;
        paintCursorAboveText = true;
        cursorOpacityAnimates = true;
        cursorColor ??= CupertinoTheme.of(context).primaryColor;
        cursorRadius ??= const Radius.circular(2.0);
        // An eyeballed value that moves the cursor slightly left of where it is
        // rendered for text on Android so its positioning more accurately matches the
        // native iOS text cursor positioning.
        //
        // This value is in device pixels, not logical pixels as is typically used
        // throughout the codebase.
        const int _iOSHorizontalOffset = -2;
        cursorOffset = Offset(
            _iOSHorizontalOffset / MediaQuery.of(context).devicePixelRatio, 0);
        break;

      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        forcePressEnabled = false;
        textSelectionControls = ms.MaterialTextSelectionControls(
            _pasteHandler); // ms.materialTextSelectionControls;
        paintCursorAboveText = false;
        cursorOpacityAnimates = false;
        cursorColor ??= themeData.cursorColor;
        break;
    }

    Widget child = RepaintBoundary(
      child: CodeEditableText(
        key: _codeEditableTextKey,
        highlighter: widget.highlighter,
        readOnly: widget.readOnly,
        showCursor: widget.showCursor,
        showSelectionHandles: _showSelectionHandles,
        controller: controller,
        focusNode: focusNode,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        style: style,
        strutStyle: widget.strutStyle,
        textAlign: widget.textAlign,
        textDirection: widget.textDirection,
        autofocus: widget.autofocus,
        autocorrect: widget.autocorrect,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        expands: widget.expands,
        selectionColor: themeData.textSelectionColor,
        selectionControls:
            widget.selectionEnabled ? textSelectionControls : null,
        onChanged: widget.onChanged,
        hideKeyboardUntilTapped: widget.hideKeyboardUntilTapped,
        onBackSpacePress: widget.onBackSpacePress,
        onEnterPress: widget.onEnterPress,
        onPasteAction: widget.onPasteAction,
        onSelectionChanged: _handleSelectionChanged,
        onEditingComplete: widget.onEditingComplete,
        onRectChanged: widget.onRectChanged,
        onSubmitted: widget.onSubmitted,
        onSelectionHandleTapped: _handleSelectionHandleTapped,
        inputFormatters: formatters,
        rendererIgnoresPointer: true,
        cursorWidth: widget.cursorWidth,
        cursorRadius: cursorRadius,
        cursorColor: cursorColor,
        cursorOpacityAnimates: cursorOpacityAnimates,
        cursorOffset: cursorOffset,
        paintCursorAboveText: paintCursorAboveText,
        backgroundCursorColor: CupertinoColors.inactiveGray,
        scrollPadding: widget.scrollPadding,
        keyboardAppearance: keyboardAppearance,
        enableInteractiveSelection: widget.enableInteractiveSelection,
        dragStartBehavior: widget.dragStartBehavior,
        scrollController: widget.scrollController,
        scrollPhysics: widget.scrollPhysics,
      ),
    );

    if (widget.decoration != null) {
      child = AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[focusNode, controller]),
        builder: (BuildContext context, Widget child) {
          return InputDecorator(
            decoration: _getEffectiveDecoration(),
            baseStyle: widget.style,
            textAlign: widget.textAlign,
            textAlignVertical: widget.textAlignVertical,
            isHovering: _isHovering,
            isFocused: focusNode.hasFocus,
            isEmpty: controller.value.text.isEmpty,
            expands: widget.expands,
            child: child,
          );
        },
        child: child,
      );
    }

    return Semantics(
      onTap: () {
        if (!_effectiveController.selection.isValid)
          _effectiveController.selection = TextSelection.collapsed(
              offset: _effectiveController.textSpan.text.length);
        _requestKeyboard();
      },
      child: Listener(
        onPointerEnter: _handlePointerEnter,
        onPointerExit: _handlePointerExit,
        child: IgnorePointer(
          ignoring: !(widget.enabled ?? widget.decoration?.enabled ?? true),
          child: TextSelectionGestureDetector(
            onTapDown: _handleTapDown,
            onForcePressStart:
                forcePressEnabled ? _handleForcePressStarted : null,
            onSingleTapUp: _handleSingleTapUp,
            onSingleTapCancel: _handleSingleTapCancel,
            onSingleLongTapStart: _handleSingleLongTapStart,
            onSingleLongTapMoveUpdate: _handleSingleLongTapMoveUpdate,
            onSingleLongTapEnd: _handleSingleLongTapEnd,
            onDoubleTapDown: _handleDoubleTapDown,
            onDragSelectionStart: _handleMouseDragSelectionStart,
            onDragSelectionUpdate: _handleMouseDragSelectionUpdate,
            behavior: HitTestBehavior.translucent,
            child: child,
          ),
        ),
      ),
    );
  }
}
