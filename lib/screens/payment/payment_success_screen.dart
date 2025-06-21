import 'package:cmc_ev/screens/stagiaire/home_screen.dart';
import 'package:flutter/material.dart';
import '../../models/event.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final Event? event;
  
  // Add event parameter to constructor
  const PaymentSuccessScreen({
    Key? key, 
    this.event,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 99, 161, 241),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 99, 161, 241),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 32),
              // Success Title
              const Text(
                'Payment Done',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              // Success Message
              const Text(
                'Your payment was successful!\nGet ready for an amazing experience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              // Action Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // This approach is safer and works better with complex navigation stacks
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/home', 
                          (route) => false, // Clear entire stack
                        ).then((_) {
                          // After returning to home, navigate to the event details again
                          if (event != null) {
                            // This is handled by your event card tap in home screen
                            // You would typically add this as a callback to handle in the parent
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Registration completed successfully!')),
                            );
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(19),
                        ),
                      ),
                      child: const Text(
                        'See ticket',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}