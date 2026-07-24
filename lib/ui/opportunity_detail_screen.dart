import 'package:flutter/material.dart';
import 'package:formative_assignment/models/opportunity.dart';
import 'package:formative_assignment/state/app_state.dart';
import 'package:formative_assignment/ui/application_form_screen.dart';

class OpportunityDetailScreen extends StatefulWidget {
  final Opportunity opportunity;
  final AppState appState;
  const OpportunityDetailScreen({super.key, required this.opportunity, required this.appState});

  @override
  State<OpportunityDetailScreen> createState() => _OpportunityDetailScreenState();
}

class _OpportunityDetailScreenState extends State<OpportunityDetailScreen> {
  final _coverLetterController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.opportunity.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.opportunity.imageUrl != null && widget.opportunity.imageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          widget.opportunity.imageUrl!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 180,
                            color: const Color(0xFFF7E6E8),
                            alignment: Alignment.center,
                            child: const Text('Image could not be loaded'),
                          ),
                        ),
                      ),
                    if (widget.opportunity.imageUrl != null && widget.opportunity.imageUrl!.isNotEmpty) const SizedBox(height: 12),
                    Text(widget.opportunity.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF7A0F1D))),
                    const SizedBox(height: 8),
                    Text(widget.opportunity.description, style: const TextStyle(height: 1.5)),
                    const SizedBox(height: 16),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [const Text('Category: ', style: TextStyle(fontWeight: FontWeight.bold)), Text(widget.opportunity.category)]),
                        const SizedBox(height: 6),
                        Row(children: [const Text('Location: ', style: TextStyle(fontWeight: FontWeight.bold)), Text(widget.opportunity.location)]),
                        const SizedBox(height: 6),
                        Row(children: [const Text('Commitment: ', style: TextStyle(fontWeight: FontWeight.bold)), Text(widget.opportunity.commitment)]),
                        const SizedBox(height: 6),
                        Row(children: [const Text('Stipend: ', style: TextStyle(fontWeight: FontWeight.bold)), Text(widget.opportunity.stipend)]),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (widget.opportunity.requiredSkills.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Required skills', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7A0F1D))),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: widget.opportunity.requiredSkills.map((skill) => Chip(label: Text(skill))).toList()),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ApplicationFormScreen(opportunity: widget.opportunity, appState: widget.appState),
                  ),
                );
              },
              child: const Text('Apply now'),
            ),
          ],
        ),
      ),
    );
  }
}
