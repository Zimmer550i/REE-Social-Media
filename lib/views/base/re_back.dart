import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ReBack extends StatelessWidget {
  final VoidCallback onTap;
  const ReBack({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SvgPicture.asset("assets/icons/back.svg",height: 24,width: 24,),
    );
  }
}
