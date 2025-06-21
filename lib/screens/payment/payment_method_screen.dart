import 'package:cmc_ev/screens/payment/payment_success_screen.dart';
import 'package:flutter/material.dart';
import '../../models/event.dart';

class PaymentMethodScreen extends StatefulWidget {
  final Event? event;
  
  const PaymentMethodScreen({
    Key? key, 
    this.event,
  }) : super(key: key);

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String? selectedMethod;
  bool saveCard = false;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // App color constants - matching home screen colors
  final Color primaryColor = const Color(0xFF37A2BC); // Matching the teal blue in home_screen
  final Color bgColor = Colors.white; // White background
  final Color cardColor = Colors.white; // White card color
  final Color textColor = Colors.black; // Text color
  final Color inputBgColor = const Color(0xFFF5F5F5); // Light gray for input backgrounds

  final List<Map<String, dynamic>> paymentMethods = [
    {'id': 'visa', 'image': 'assets/payment/visa.png'},
    {'id': 'mastercard', 'image': 'assets/payment/mastercard.png'},
    {'id': 'paypal', 'image': 'assets/payment/paypal.png'},
    // {'id': 'gpay', 'image': 'assets/payment/gpay.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: inputBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back, color: textColor),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Your Payment\nMethode',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Payment Methods Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: paymentMethods.map((method) {
                      final isSelected = selectedMethod == method['id'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedMethod = method['id'];
                          });
                        },
                        child: Container(
                          width: 80,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor.withOpacity(0.1) : inputBgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? primaryColor : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Image.asset(
                            method['image'],
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  // Show event payment info if we have event details
                  if (widget.event != null) ...{
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: inputBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryColor.withOpacity(0.2), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment for:',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.event!.title,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Amount:',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              Text(
                                '${widget.event!.ticketPrice} MAD',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  },
                  // Form Fields
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: _inputDecoration('First Name'),
                          style: TextStyle(color: textColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          decoration: _inputDecoration('Last Name'),
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: _inputDecoration('Card Number*'),
                    style: TextStyle(color: textColor),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: _inputDecoration('MM*'),
                          style: TextStyle(color: textColor),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          decoration: _inputDecoration('YY*'),
                          style: TextStyle(color: textColor),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: _inputDecoration('CVV/CVC*'),
                    style: TextStyle(color: textColor),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: _inputDecoration('Phone Number*'),
                    style: TextStyle(color: textColor),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: saveCard,
                          onChanged: (value) {
                            setState(() {
                              saveCard = value ?? false;
                            });
                          },
                          fillColor: MaterialStateProperty.resolveWith(
                            (states) => states.contains(MaterialState.selected)
                                ? primaryColor
                                : Colors.transparent,
                          ),
                          side: BorderSide(color: Colors.grey[400]!),
                          checkColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Save the card info for Later',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          // Add loading indicator
                          setState(() {
                            _isLoading = true;
                          });
                          
                          // Simulate payment processing (can be replaced with real payment)
                          Future.delayed(const Duration(seconds: 2), () {
                            // Navigate to success screen and wait for it to complete
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentSuccessScreen(
                                  event: widget.event,
                                ),
                              ),
                            ).then((_) {
                              // Important: Now explicitly pop with a TRUE result to indicate successful payment
                              Navigator.of(context).pop(true); // This sends TRUE back to EventDetailsView
                            });
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(19),
                        ),
                        elevation: 2,
                        shadowColor: primaryColor.withOpacity(0.4),
                      ),
                      child: _isLoading 
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'Pay Now',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600]),
      filled: true,
      fillColor: inputBgColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}