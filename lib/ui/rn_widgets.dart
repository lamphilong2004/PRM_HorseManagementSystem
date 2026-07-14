import 'package:flutter/material.dart';

const rnSecondaryColor = Color(0xFF666666);
const rnInputBorderColor = Color(0xFFDDDDDD);
const rnSelectedColor = Color(0xFF11AA77);
const rnDarkTextColor = Color(0xFF333333);

const rnHeader28 = TextStyle(fontSize: 28, fontWeight: FontWeight.w700);
const rnHeader22 = TextStyle(fontSize: 22, fontWeight: FontWeight.w700);
const rnHeader20 = TextStyle(fontSize: 20, fontWeight: FontWeight.w700);
const rnSecondaryText = TextStyle(color: rnSecondaryColor);
const rnSemiBoldText = TextStyle(fontWeight: FontWeight.w600);

class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

class SpacedColumn extends StatelessWidget {
  const SpacedColumn({
    super.key,
    required this.children,
    this.scrollable = false,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final bool scrollable;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      crossAxisAlignment: crossAxisAlignment,
      children: _withGaps(children),
    );

    if (!scrollable) return column;
    return SingleChildScrollView(child: column);
  }

  List<Widget> _withGaps(List<Widget> children) {
    final spaced = <Widget>[];
    for (var index = 0; index < children.length; index++) {
      spaced.add(children[index]);
      if (index != children.length - 1) {
        spaced.add(const SizedBox(height: 12));
      }
    }
    return spaced;
  }
}

Widget rnButton({
  required String title,
  required VoidCallback? onPressed,
  bool fullWidth = true,
}) {
  final button = ElevatedButton(
    onPressed: onPressed,
    child: Text(title),
  );
  if (!fullWidth) return button;
  return SizedBox(width: double.infinity, child: button);
}

InputDecoration rnInputDecoration({String? hintText}) {
  return InputDecoration(
    hintText: hintText,
    contentPadding: const EdgeInsets.all(10),
    isDense: true,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: rnInputBorderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: rnInputBorderColor),
    ),
  );
}

Future<void> showRnAlert(
  BuildContext context,
  String title,
  String message,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Widget loadingText() => const Text('Loading…', style: rnSecondaryText);

Widget selectableTextRow({
  required String text,
  required bool selected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        '${selected ? '✓ ' : ''}$text',
        style: TextStyle(color: selected ? rnSelectedColor : rnDarkTextColor),
      ),
    ),
  );
}
