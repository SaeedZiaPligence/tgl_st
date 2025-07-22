import 'dart:ui';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:go_sell_sdk_flutter/go_sell_sdk_flutter.dart';
import 'package:go_sell_sdk_flutter/model/models.dart';

class MuseumScreen extends StatefulWidget {
  const MuseumScreen({super.key});

  @override
  State<MuseumScreen> createState() => _MuseumScreenState();
}

class _MuseumScreenState extends State<MuseumScreen> {
  String ticketType = 'Single';
  String paymentMethod = 'Cash';

  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        title: const Text('Museum'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Color(0xFF4A148C),
                Colors.black,
              ],
              stops: [0.0, 1.0],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Color(0xFF4A148C),
                Colors.black,
              ],
              stops: [0.0, 1.0],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Event image
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    'https://picsum.photos/400/200',
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                // Description
                const Text(
                  'Experience the wonders of the museum with guided tours and exclusive exhibits. '
                      'Select a single ticket for your visit.',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Ticket selection container with glass effect (Single only)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Ticket',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              setState(() => ticketType = 'Single');
                              _showTicketDialog();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: ticketType == 'Single'
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.event_seat, size: 48, color: Colors.white),
                                  const SizedBox(height: 6),
                                  const Text('Single', style: TextStyle(color: Colors.white, fontSize: 14)),
                                  const SizedBox(height: 6),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.orange.withOpacity(0.8),
                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                    onPressed: () {
                                      setState(() => ticketType = 'Single');
                                     _showTicketDialog();
                                    },
                                    child: const Text(
                                      'Select Ticket',
                                      style: TextStyle(color: Colors.white, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Payment method container with glass effect
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Payment Method',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: paymentMethod,
                            dropdownColor: Colors.black54,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            iconEnabledColor: Colors.white,
                            style: const TextStyle(color: Colors.white),
                            items: [
                              DropdownMenuItem(
                                value: 'Cash',
                                child: Row(
                                  children: const [
                                    Icon(Icons.money, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Cash'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'K-Net',
                                child: Row(
                                  children: const [
                                    Icon(Icons.credit_card, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('K-Net'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'Apple Pay',
                                child: Row(
                                  children: const [
                                    Icon(Icons.apple, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Apple Pay'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                paymentMethod = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // The Pay Now button is moved to ticket dialog.
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<void> setupSDKSession() async {
    try {
       GoSellSdkFlutter.sessionConfigurations(
        trxMode: TransactionMode.PURCHASE,
        transactionCurrency: "usd",
        amount: 10, // amount as String
        customer: Customer(
          customerId: "fsdf", // optional
          email: "test@test.com",
          isdNumber: "965",
          number: "00000000",
          firstName: "test",
          middleName: "test",
          lastName: "test",
          metaData: null,
        ),
        paymentItems: [],
        taxes: [],
        shippings: [],
        postURL: "https://api.sandbox.tap.company",
        paymentDescription: "Test Payment",
        paymentMetaData: {
          "meta1": "value1",
          "meta2": "value2",
        },
        paymentReference: Reference(
          acquirer: "acquirer",
          gateway: "gateway",
          payment: "payment",
          track: "track",
          transaction: "trans_910101",
          order: "order_262625",
        ),
        paymentStatementDescriptor: "Test Descriptor",
        isUserAllowedToSaveCard: true,
        isRequires3DSecure: false,
        receipt: Receipt(true, false),
        authorizeAction: AuthorizeAction(
          type: AuthorizeActionType.CAPTURE,
          timeInHours: 10,
        ),
        destinations: null, // optional
        merchantID: "11945082",
        allowedCadTypes: CardType.ALL,
        applePayMerchantID: "merchant.applePayMerchantID",
        allowsToSaveSameCardMoreThanOnce: false,
        cardHolderName: "Test User",
        allowsToEditCardHolderName: false,
        supportedPaymentMethods: ["card", "knet", "mada", "amex", "applepay", "benefit"], // or ["ALL"]
        appearanceMode: SDKAppearanceMode.fullscreen,
        paymentType: PaymentType.ALL,
        sdkMode: SDKMode.Sandbox,
      );

      final chargeResponse = await GoSellSdkFlutter.startPaymentSDK;
     // print("Payment Status: ${chargeResponse.status}");
    } catch (e) {
      print("Error starting payment: $e");
    }
  }

  void _showTicketDialog() {
    int peopleCount = 1;
    double pricePerPerson = 10.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double total = peopleCount * pricePerPerson;
            return Dialog(
              backgroundColor: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Select Number of People', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('People', style: TextStyle(color: Colors.white)),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, color: Colors.white),
                                  onPressed: peopleCount > 1
                                      ? () {
                                    setDialogState(() {
                                      peopleCount--;
                                    });
                                  }
                                      : null,
                                ),
                                Text('$peopleCount', style: const TextStyle(color: Colors.white)),
                                IconButton(
                                  icon: const Icon(Icons.add, color: Colors.white),
                                  onPressed: () {
                                    setDialogState(() {
                                      peopleCount++;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('Total: KD ${total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: () {
                            final double amount = total; // Amount to be charged (1 KWD in this case)
                            final String currency = 'KWD'; // Currency
                            final String tokenId = 'your_token_id_here'; // Replace with actual token
                            final String redirectUrl = 'http://your_website.com/redirect_url'; // Replace with actual redirect URL

                            setupSDKSession();
                            //  Navigator.pop(context);
                           // _showTicketGeneratedDialog(peopleCount, total, pricePerPerson);
                          },
                          child: Text('Pay Now (KD ${total.toStringAsFixed(2)})', style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTicketGeneratedDialog(int peopleCount, double total, double pricePerPerson) {
    final ticketNumber = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    final now = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Screenshot(
            controller: _screenshotController,
            child: TicketCard(
              title: "The Gaming Hub",
              date: now,
              price: total,
              ticketNo: ticketNumber,
              peopleCount: peopleCount,
              onDownload: () async {
                try {
                  // Capture image bytes
                  Uint8List? imageBytes = await _screenshotController.capture();
                  if (imageBytes == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to capture ticket image.')),
                    );
                    return;
                  }

                  // Save bytes to temporary file
                  final directory = await getTemporaryDirectory();
                  final filePath = path.join(directory.path, 'ticket_$ticketNumber.png');
                  final file = File(filePath);
                  await file.writeAsBytes(imageBytes);

                  // Save to gallery (removed GallerySaver)
                  // TODO: Implement saving image to gallery using platform-specific code or another package.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ticket image saved to temporary file, but not added to gallery.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving ticket: $e')),
                  );
                }
              },
              paymentMethod: paymentMethod,
            ),
          ),
        );
      },
    );
  }
}

class TicketCard extends StatelessWidget {
  final String title;
  final DateTime date;
  final double price;
  final String ticketNo;
  final int peopleCount;
  final VoidCallback onDownload;
  final String paymentMethod;

  const TicketCard({
    super.key,
    required this.title,
    required this.date,
    required this.price,
    required this.ticketNo,
    required this.peopleCount,
    required this.onDownload,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final dateString = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    final timeString = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    return Center(
      child: ClipPath(
        clipper: TicketClipper(),
        child: Container(
          width: 330,
          color: Colors.black.withOpacity(0.99),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 2),
              // Removed dateString below the title
              // Removed: Text(dateString, style: const TextStyle(color: Colors.white70, fontSize: 15)),
              const SizedBox(height: 8),
              Text("VIP Hall", style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 6),
              Text(
                dateString,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Text(
                timeString,
                style: const TextStyle(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 18),
              // Removed Order number row and its text
              // Ticket number prominently displayed
              SizedBox(
                height: 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      ticketNo,
                      style: const TextStyle(
                        fontSize: 44,
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text('Ticket Number', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text("Price: KD ${price.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text("People: $peopleCount", style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: onDownload,
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text("Download Ticket", style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 14),
              if (paymentMethod == 'Cash')
                const Text(
                  'Show this ticket to staff and pay cash to validate.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                )
              else
                const Text(
                  'Online payment not yet implemented.\nOnce available, ticket will be generated automatically.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double notchRadius = 24;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height / 2 - notchRadius);
    path.arcToPoint(
      Offset(0, size.height / 2 + notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, size.height / 2 + notchRadius);
    path.arcToPoint(
      Offset(size.width, size.height / 2 - notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(TicketClipper oldClipper) => false;
}