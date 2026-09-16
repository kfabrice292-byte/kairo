import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../core/models/user_model.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AshtechPaymentDialog extends StatefulWidget {
  final UserModel user;
  final String paymentType; // 'cv' or 'premium'
  final VoidCallback onSuccess;

  const AshtechPaymentDialog({
    Key? key,
    required this.user,
    required this.paymentType,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<AshtechPaymentDialog> createState() => _AshtechPaymentDialogState();
}

class _AshtechPaymentDialogState extends State<AshtechPaymentDialog> {
  final List<Map<String, dynamic>> _commonCountries = [
    {'code': 'CI', 'name': 'Côte d\'Ivoire', 'operators': ['Orange Money', 'MTN Mobile Money', 'Moov Money', 'Wave']},
    {'code': 'SN', 'name': 'Sénégal', 'operators': ['Orange Money', 'Free Money', 'Wave']},
    {'code': 'CM', 'name': 'Cameroun', 'operators': ['Orange Money', 'MTN Mobile Money']},
    {'code': 'BF', 'name': 'Burkina Faso', 'operators': ['Orange Money', 'Moov Money']},
    {'code': 'CD', 'name': 'RD Congo', 'operators': ['Airtel Money', 'Orange Money', 'Vodacom M-Pesa', 'Afrimoney']},
    {'code': 'GN', 'name': 'Guinée', 'operators': ['Orange Money', 'MTN Mobile Money']},
    {'code': 'BJ', 'name': 'Bénin', 'operators': ['MTN Mobile Money', 'Moov Money']},
    {'code': 'TG', 'name': 'Togo', 'operators': ['Flooz (Moov)', 'T-Money']},
  ];

  String? _selectedCountry;
  String? _selectedOperator;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  String _step = 'form'; // 'form', 'otp', 'ussd_push', 'wave'
  
  String? _reference;
  String? _ussdCode;
  String? _waveUrl;

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.user.phone ?? '';
    _selectedCountry = _commonCountries.first['code'];
    _selectedOperator = _commonCountries.first['operators'].first;
  }

  Future<void> _submitPayment({String? otp}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final productId = widget.paymentType == 'premium' ? 'premium_monthly' : 'cv_export';

      final body = {
        'uid': widget.user.uid,
        'productId': productId,
        'phone': _phoneController.text.trim(),
        'operator': _selectedOperator,
        'country_code': _selectedCountry,
      };

      if (otp != null) {
        body['otp'] = otp;
      }
      if (_reference != null) {
        body['reference'] = _reference;
      }

      final callable = FirebaseFunctions.instance.httpsCallable('initiatePayment');
      final result = await callable.call(body);
      final data = result.data['data'] as Map<String, dynamic>;
      final statusCode = result.data['status'] as int;

      if (statusCode == 202) {
        if (data['flow'] == 'wave') {
          // Flow Wave
          _waveUrl = data['wave_url'];
          setState(() {
            _step = 'wave';
          });
          if (_waveUrl != null) {
            launchUrl(Uri.parse(_waveUrl!), mode: LaunchMode.externalApplication);
          }
        } else {
          // Flow USSD Push
          setState(() {
            _reference = data['reference'];
            _step = 'ussd_push';
          });
        }
      } else if (statusCode == 400 && data['error'] == 'otp_required') {
        // Flow OTP (USSD or SMS)
        setState(() {
          _reference = data['reference'];
          _ussdCode = data['ussd_code'];
          _step = 'otp';
        });
      } else {
        // Erreur
        setState(() {
          _error = data['message'] ?? 'Erreur lors de l\'initialisation.';
        });
      }
    } on FirebaseFunctionsException catch (e) {
      setState(() {
        _error = e.message ?? 'Erreur interne du serveur.';
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur réseau : ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Traitement en cours...'),
        ],
      );
    }

    if (_step == 'ussd_push') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.phone_android, size: 48, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            'Veuillez valider',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Un message a été envoyé sur votre téléphone. Veuillez saisir votre code secret pour valider le paiement.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onSuccess();
            },
            child: const Text('J\'ai validé le paiement'),
          )
        ],
      );
    }

    if (_step == 'wave') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code, size: 48, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            'Paiement Wave',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Veuillez ouvrir l\'application Wave pour confirmer le paiement.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_waveUrl != null)
            ElevatedButton(
              onPressed: () {
                launchUrl(Uri.parse(_waveUrl!), mode: LaunchMode.externalApplication);
              },
              child: const Text('Ouvrir Wave'),
            ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onSuccess();
            },
            child: const Text('J\'ai payé'),
          )
        ],
      );
    }

    if (_step == 'otp') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Validation OTP',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_ussdCode != null)
            Text(
              'Veuillez composer le $_ussdCode sur votre téléphone pour générer votre code OTP.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            )
          else
            const Text(
              'Un code OTP vous a été envoyé par SMS.',
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _otpController,
            decoration: const InputDecoration(
              labelText: 'Code OTP',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_otpController.text.isNotEmpty) {
                _submitPayment(otp: _otpController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Valider'),
          ),
          TextButton(
            onPressed: () => setState(() { _step = 'form'; _error = null; }),
            child: const Text('Retour'),
          )
        ],
      );
    }

    // Default form
    final currentCountryObj = _commonCountries.firstWhere((c) => c['code'] == _selectedCountry, orElse: () => _commonCountries.first);
    final List<String> operators = List<String>.from(currentCountryObj['operators']);

    if (!operators.contains(_selectedOperator)) {
      _selectedOperator = operators.first;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Paiement sécurisé',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedCountry,
          decoration: const InputDecoration(
            labelText: 'Pays',
            border: OutlineInputBorder(),
          ),
          items: _commonCountries.map((c) {
            return DropdownMenuItem<String>(
              value: c['code'],
              child: Text(c['name']),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedCountry = val;
            });
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedOperator,
          decoration: const InputDecoration(
            labelText: 'Opérateur',
            border: OutlineInputBorder(),
          ),
          items: operators.map((o) {
            return DropdownMenuItem<String>(
              value: o,
              child: Text(o),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedOperator = val;
            });
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Numéro de téléphone Mobile Money',
            border: OutlineInputBorder(),
            hintText: 'Ex: 0700000000',
          ),
          keyboardType: TextInputType.phone,
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            if (_phoneController.text.isNotEmpty) {
              _submitPayment();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Payer'),
        ),
      ],
    );
  }
}
