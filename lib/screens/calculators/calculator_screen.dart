import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

String money(num value) {
  final isNegative = value < 0;
  final absoluteValue = value.abs();
  final rounded = absoluteValue.round().toString();

  if (rounded.length <= 3) {
    return '${isNegative ? '-₹' : '₹'}$rounded';
  }

  final lastThreeDigits = rounded.substring(rounded.length - 3);
  final remainingDigits = rounded.substring(0, rounded.length - 3);

  final formattedRemaining = remainingDigits.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
    (match) => '${match.group(1)},',
  );

  return '${isNegative ? '-₹' : '₹'}$formattedRemaining$lastThreeDigits';
}

class MoneyText extends StatelessWidget {
  const MoneyText(
    this.value, {
    super.key,
    this.style,
  });

  final num value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      money(value),
      style: style,
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({
    super.key,
    required this.type,
    required this.title,
  });

  final String type;
  final String title;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final fields = <String, TextEditingController>{};

  double result = 0;
  double result2 = 0;
  String message = '';

  @override
  void initState() {
    super.initState();

    for (final key in [
      'income',
      'deduction',
      'ctc',
      'basic',
      'hra',
      'rent',
      'salary',
      'years',
      'age',
      'retire',
      'increment',
      'rate',
    ]) {
      fields[key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in fields.values) {
      controller.dispose();
    }

    super.dispose();
  }

  TextField input(
    String key,
    String label, {
    String? hint,
  }) {
    return TextField(
      controller: fields[key],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }

  void calculate() {
    double number(String key) {
      return double.tryParse(fields[key]!.text.trim()) ?? 0;
    }

    setState(() {
      message = '';

      if (widget.type == 'tax') {
        final income = number('income');
        final deductions = number('deduction');

        final oldRegimeTax = taxOld(income - deductions);
        final newRegimeTax = taxNew(income - 75000);

        result = oldRegimeTax;
        result2 = newRegimeTax;

        message = oldRegimeTax < newRegimeTax
            ? 'Old Regime saves ${money(newRegimeTax - oldRegimeTax)}'
            : 'New Regime saves ${money(oldRegimeTax - newRegimeTax)}';
      } else if (widget.type == 'salary') {
        final ctc = number('ctc');
        final basic = ctc * 0.4;
        final pf = (basic * 0.12).clamp(0, 1800 * 12);

        result = ctc - pf - 2400;
        result2 = result / 12;
        message = 'Basic ${money(basic)} · PF ${money(pf)}';
      } else if (widget.type == 'hra') {
        final basic = number('basic');
        final hra = number('hra');
        final rent = number('rent');

        final rentBasedExemption = rent - basic * 0.1;
        final salaryBasedLimit = basic * 0.5;

        result = [
          hra,
          rentBasedExemption,
          salaryBasedLimit,
        ].reduce((a, b) => a < b ? a : b).clamp(0, double.infinity);

        result2 = (hra - result).clamp(0, double.infinity);

        message =
            'Exempt: ${money(result)} · Taxable: ${money(result2)}';
      } else if (widget.type == 'gratuity') {
        result = 15 * number('salary') * number('years') / 26;

        message = number('years') < 5
            ? 'Usually payable after 5 years of service.'
            : 'Eligible under the 5-year rule.';
      } else {
        final currentBasic = number('salary');
        final currentAge = number('age');
        final retirementAge =
            number('retire') > 0 ? number('retire') : 58;
        final annualIncrement =
            number('increment') > 0 ? number('increment') : 5;
        final interestRate =
            (number('rate') > 0 ? number('rate') : 8.25) / 100;

        final years = retirementAge - currentAge;
        final annualContribution = currentBasic * 0.12 * 12;
        final growthFactor =
            (1 + interestRate) * (1 + annualIncrement / 100);
        final corpus = growthFactor == 1
            ? annualContribution * years
            : annualContribution *
                ((pow(growthFactor, years) - 1) /
                    (growthFactor - 1));

        result = corpus;
        result2 = years;
        message =
            'Estimated corpus after ${years.toStringAsFixed(0)} years';
      }
    });
  }

  double pow(double base, double exponent) {
    var value = 1.0;

    for (var i = 0; i < exponent; i++) {
      value *= base;
    }

    return value;
  }

  double taxOld(double income) {
    if (income <= 400000) return 0;
    if (income <= 800000) return (income - 400000) * 0.05;
    if (income <= 1200000) {
      return 20000 + (income - 800000) * 0.10;
    }
    if (income <= 1600000) {
      return 60000 + (income - 1200000) * 0.15;
    }
    if (income <= 2000000) {
      return 120000 + (income - 1600000) * 0.20;
    }
    if (income <= 2400000) {
      return 200000 + (income - 2000000) * 0.25;
    }

    return 300000 + (income - 2400000) * 0.30;
  }

  double taxNew(double income) {
    return taxOld(income);
  }

  @override
  Widget build(BuildContext context) {
    final keys = widget.type == 'tax'
        ? ['income', 'deduction']
        : widget.type == 'salary'
            ? ['ctc']
            : widget.type == 'hra'
                ? ['basic', 'hra', 'rent']
                : widget.type == 'gratuity'
                    ? ['salary', 'years']
                    : ['salary', 'age', 'retire', 'increment', 'rate'];

    final labels = {
      'income': 'Annual income',
      'deduction': '80C + 80D deductions',
      'ctc': 'Annual CTC',
      'basic': 'Monthly basic salary',
      'hra': 'Monthly HRA received',
      'rent': 'Monthly rent paid',
      'salary': widget.type == 'gratuity'
          ? 'Last drawn salary (basic + DA)'
          : 'Current basic salary',
      'years': 'Years of service',
      'age': 'Current age',
      'retire': 'Retirement age (default 58)',
      'increment': 'Annual increment % (default 5)',
      'rate': 'EPF interest % (default 8.25)',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...keys.map(
            (key) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: input(key, labels[key]!),
            ),
          ),
          FilledButton.icon(
            onPressed: calculate,
            icon: const Icon(Icons.calculate),
            label: const Text('Calculate'),
          ),
          if (message.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Result',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    MoneyText(
                      result,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (result2 > 0)
                      Text('Comparison / monthly: ${money(result2)}'),
                    Text(message),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Share.share(
                              '${widget.title}: ${money(result)}\n$message',
                            );
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Result saved locally for this session',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Save'),
                        ),
                      ],
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
