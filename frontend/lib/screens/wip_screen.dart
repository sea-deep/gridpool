import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/widgets/page_header.dart';
import 'package:frontend/widgets/page_scaffold.dart';

class WipScreen extends StatelessWidget {
  final String title;

  const WipScreen({super.key, this.title = 'Work in Progress'});

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      child: Column(
        children: [
          PageHeader(
            title: title,
            actions: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
            ],
          ),
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.construction_rounded, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'This screen is under construction.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
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
