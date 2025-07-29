import 'package:flutter/material.dart';
import 'package:reporting_app/screens/signin_screen.dart';
import 'package:reporting_app/screens/signup_screen.dart';
import 'package:reporting_app/widgets/custom_scaffold.dart';
import 'package:reporting_app/widgets/welcome_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        children: [
          /*Flexible(
              flex: 8,
              child: Container(
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 40.0,
                ),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                            text: 'NISHTHA\n',
                            style: TextStyle(
                              fontSize: 55.0,
                              fontWeight: FontWeight.w600,
                            ),
                        ),
                        TextSpan(
                            text:
                            '\nAn efficient task assigning and reporting app',
                            style: TextStyle(
                              fontSize: 27,
                              // height: 0,
                            ),
                        ),
                      ],
                    ),
                  ),

              )),*/
          Flexible(
            flex: 1,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Row(
                children: [
                  const Expanded(
                    child: WelcomeButton(
                      buttonText: 'Sign in',
                      onTap: SignInScreen(),
                      color: Color(0x800C795A),
                      textColor: Colors.white,
                    ),
                  ),

                  Expanded(
                    child: WelcomeButton(
                      buttonText: 'Sign up',
                      onTap: const SignUpScreen(),
                      color: Color(0x800C795A),
                      textColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}