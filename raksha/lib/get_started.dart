import 'package:flutter/material.dart';
import 'package:raksha/login.dart';
import 'package:raksha/mybutton.dart';

// Changed to StatefulWidget to handle orientation changes
class GetStartedPage extends StatefulWidget {
  const GetStartedPage({super.key});

  @override
  State<GetStartedPage> createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<GetStartedPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    setState(() {}); // Rebuild the widget when metrics change
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final size = MediaQuery.of(context).size;
    // ignore: unused_local_variable
    final padding = MediaQuery.of(context).padding;

    // Calculate responsive dimensions
    final logoSize = size.width * 0.3; // 30% of screen width
    final bottomPadding = size.height * 0.15; // 15% of screen height

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("images/bg1.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  _buildCenteredContent(
                    context,
                    logoSize,
                    constraints,
                  ),
                  _buildGetStartedButton(
                    context,
                    bottomPadding,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCenteredContent(
    BuildContext context,
    double logoSize,
    BoxConstraints constraints,
  ) {
    // Calculate responsive text sizes
    final titleSize = constraints.maxWidth * 0.12; // 12% of width
    final sloganSize = constraints.maxWidth * 0.045; // 4.5% of width

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Hero(
            tag: 'raksha_logo',
            child: Image.asset(
              "images/rakshalogo.png",
              height: logoSize,
              width: logoSize,
              semanticLabel: 'Raksha Logo',
            ),
          ),
          SizedBox(height: constraints.maxHeight * 0.02), // 2% of height

          _buildAppTitle(titleSize),
          SizedBox(height: constraints.maxHeight * 0.01), // 1% of height
          _buildSlogan(sloganSize),
        ],
      ),
    );
  }

  Widget _buildAppTitle(double fontSize) {
    return Text(
      "RAKSHA",
      style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'quickie',
          color: Colors.black),
    );
  }

  Widget _buildSlogan(double fontSize) {
    return Text(
      "CONNECTING HELP WITH HOPE",
      textAlign: TextAlign.center,
      style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'quickie',
          color: Colors.black),
    );
  }

  Widget _buildGetStartedButton(BuildContext context, double bottomPadding) {
    final buttonWidth =
        MediaQuery.of(context).size.width * 0.8; // 80% of screen width

    return Positioned(
      bottom: bottomPadding,
      left: 0,
      right: 0,
      child: Center(
        child: SizedBox(
          width: buttonWidth,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Mybutton(
              text: "Get Started",
              onTap: () => _showLoginModal(context),
            ),
          ),
        ),
      ),
    );
  }

  void _showLoginModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => LoginSignupModal(),
    );
  }
}
