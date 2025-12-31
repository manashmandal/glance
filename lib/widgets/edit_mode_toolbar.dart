import 'package:flutter/material.dart';

class EditModeToolbar extends StatelessWidget {
  final VoidCallback onDone;
  final VoidCallback onReset;

  const EditModeToolbar({
    super.key,
    required this.onDone,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D35).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.dashboard_customize,
            color: Color(0xFF3B82F6),
            size: 20,
          ),
          const SizedBox(width: 12),
          const Text(
            'Edit Mode',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 1,
            height: 24,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 16),
          _buildButton(
            label: 'Reset',
            icon: Icons.restart_alt,
            onPressed: onReset,
            isPrimary: false,
          ),
          const SizedBox(width: 12),
          _buildButton(
            label: 'Done',
            icon: Icons.check,
            onPressed: onDone,
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isPrimary
                ? const Color(0xFF3B82F6)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isPrimary ? Colors.white : Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
