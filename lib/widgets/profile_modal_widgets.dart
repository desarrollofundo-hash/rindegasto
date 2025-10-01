import 'package:flutter/material.dart';
import '../controllers/profile_modal_controller.dart';

class ProfileModalWidgets {
  static Widget buildHeaderWithCloseButton(
    ProfileModalController controller,
    VoidCallback onClose,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Espacio para alinear el título centrado
          const SizedBox(width: 40),

          // Indicador de arrastre
          Expanded(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: controller.isDragging
                        ? Colors.grey[500]
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                if (controller.isDragging) ...[
                  const SizedBox(height: 8),
                  Text(
                    controller.totalDragOffset > 100
                        ? "Suelta para cerrar"
                        : "Desliza para cerrar",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Botón de cerrar (X)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: controller.isDragging ? 0.0 : 1.0,
            child: IconButton(
              onPressed: onClose,
              icon: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 20, color: Colors.grey),
              ),
              splashRadius: 20,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildTitleSection(ProfileModalController controller) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: controller.isDragging ? 0.7 : 1.0,
      child: Column(
        children: [
          const Text(
            "Perfil Profesional",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1D1F),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Actualiza tu información personal",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildAnimatedAvatar(
    ProfileModalController controller,
    VoidCallback onAvatarTap,
  ) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: controller.isDragging ? 0.5 : 1.0,
      child: AnimatedScale(
        scale: controller.avatarScale,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: GestureDetector(
          onTap: controller.isDragging ? null : onAvatarTap,
          child: MouseRegion(
            cursor: controller.isDragging
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.blue[400]!, Colors.purple[400]!],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                controller.avatarScale == 0.8 ? 0.3 : 0.1,
                              ),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: controller.isDragging ? 0.0 : 1.0,
                  child: Text(
                    "Toca para cambiar foto",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildAnimatedForm(ProfileModalController controller) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: controller.isDragging ? 0.3 : 1.0,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: controller.animationController,
                curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
              ),
            ),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: controller.animationController,
              curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
            ),
          ),
          child: Column(
            children: [
              buildAnimatedFormSection(
                controller: controller,
                title: "EMPRESA",
                icon: Icons.info_outline,
                fields: [
                  buildAnimatedField(
                    controller: controller,
                    index: 4,
                    label: "Empresa",
                    hint: "Ej: Tech Solutions SA",
                  ),
                  buildAnimatedField(
                    controller: controller,
                    index: 5,
                    label: "RUC",
                    hint: "M12432932985",
                  ),
                ],
                delay: 200,
              ),
              const SizedBox(height: 24),
              buildAnimatedFormSection(
                controller: controller,
                title: "Información Personal",
                icon: Icons.person_outline,
                fields: [
                  buildAnimatedField(
                    controller: controller,
                    index: 0,
                    label: "Nombre completo",
                    hint: "Ej: Ana Rodríguez",
                  ),
                  buildAnimatedField(
                    controller: controller,
                    index: 1,
                    label: "Dni",
                    hint: "Ej: 12345678",
                  ),
                ],
                delay: 0,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildAnimatedFormSection({
    required ProfileModalController controller,
    required String title,
    required IconData icon,
    required List<Widget> fields,
    required int delay,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + delay),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      curve: Curves.easeInOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...fields,
        ],
      ),
    );
  }

  static Widget buildAnimatedField({
    required ProfileModalController controller,
    required int index,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    String displayValue = controller.getFieldValue(index);
    bool isReadOnly = controller.isFieldReadOnly(index);

    return AnimatedContainer(
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutBack,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              decoration: BoxDecoration(
                color: isReadOnly ? Colors.grey[100] : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isReadOnly
                      ? Colors.grey[300]!
                      : (controller.focusNodes[index].hasFocus
                            ? Colors.blue[400]!
                            : Colors.grey[200]!),
                  width: controller.focusNodes[index].hasFocus ? 1.5 : 1.0,
                ),
                boxShadow: controller.focusNodes[index].hasFocus && !isReadOnly
                    ? [
                        BoxShadow(
                          color: Colors.blue[100]!,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: IgnorePointer(
                ignoring: controller.isDragging,
                child: TextField(
                  focusNode: controller.focusNodes[index],
                  keyboardType: keyboardType,
                  readOnly: isReadOnly,
                  controller: isReadOnly
                      ? (TextEditingController()..text = displayValue)
                      : null,
                  decoration: InputDecoration(
                    hintText: isReadOnly ? null : hint,
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: isReadOnly ? Colors.grey[700] : Colors.black,
                    fontWeight: isReadOnly
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildAnimatedActionButtons(
    ProfileModalController controller,
    VoidCallback onLogout,
    VoidCallback onCancel,
  ) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: controller.isDragging ? 0.0 : 1.0,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: controller.animationController,
                curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
              ),
            ),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: controller.animationController,
              curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
            ),
          ),
          child: Column(
            children: [
              // Botón de cerrar sesión
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: Colors.red.withOpacity(0.3),
                  ),
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text(
                    "Cerrar sesión",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Botón secundario para solo cerrar el modal
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: 1.0,
                child: TextButton(
                  onPressed: onCancel,
                  child: Text(
                    "Cancelar",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
