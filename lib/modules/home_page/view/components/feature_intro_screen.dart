// import 'package:car_route/modules/global/widgets/global_text.dart';
// import 'package:flutter/material.dart';
//
// class FeatureIntroSheet extends StatefulWidget {
//   const FeatureIntroSheet({super.key});
//
//   @override
//   State<FeatureIntroSheet> createState() => _FeatureIntroSheetState();
// }
//
// class _FeatureIntroSheetState extends State<FeatureIntroSheet> {
//   final PageController _controller = PageController();
//   int currentPage = 0;
//
//   final List<_Feature> features = const [
//     _Feature(
//       icon: Icons.place_outlined,
//       title: "Tap on Map to Set Locations",
//       description:
//           "Easily select your start and destination points by tapping directly on the map for quick and intuitive route planning.",
//     ),
//     _Feature(
//       icon: Icons.search,
//       title: "Search Address to Pin Location",
//       description:
//           "Enter any address to see a list of matching locations and place your desired point on the map with a single tap.",
//     ),
//     _Feature(
//       icon: Icons.route,
//       title: "Get Accurate Route Information",
//       description:
//           "Instantly view calculated route details including distance and estimated duration based on your selected locations.",
//     ),
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: MediaQuery.of(context).size.height * 0.85,
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//       child: Column(
//         children: [
//           const SizedBox(height: 10),
//           Container(
//             height: 5,
//             width: 40,
//             decoration: BoxDecoration(
//               color: Colors.grey[400],
//               borderRadius: BorderRadius.circular(5),
//             ),
//           ),
//           const SizedBox(height: 24),
//           Expanded(
//             child: PageView.builder(
//               controller: _controller,
//               itemCount: features.length,
//               onPageChanged: (index) {
//                 setState(() {
//                   currentPage = index;
//                 });
//               },
//               itemBuilder: (_, index) {
//                 final feature = features[index];
//                 return Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(feature.icon, size: 80, color: Colors.lightBlue),
//                     const SizedBox(height: 24),
//                     Text(
//                       feature.title,
//                       style: const TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       feature.description,
//                       style: const TextStyle(fontSize: 16),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 );
//               },
//             ),
//           ),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: List.generate(
//               features.length,
//               (index) => AnimatedContainer(
//                 duration: const Duration(milliseconds: 300),
//                 margin: const EdgeInsets.symmetric(horizontal: 4),
//                 width: currentPage == index ? 16 : 8,
//                 height: 8,
//                 decoration: BoxDecoration(
//                   color: currentPage == index ? Colors.lightBlue : Colors.grey,
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 24),
//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: () {
//                     Navigator.pop(context); // Skip
//                   },
//                   style: OutlinedButton.styleFrom(
//                     minimumSize: const Size.fromHeight(48),
//                     side: const BorderSide(color: Colors.lightBlue),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: const GlobalText(
//                     "Skip",
//                     color: Colors.lightBlue,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: () {
//                     if (currentPage == features.length - 1) {
//                       Navigator.pop(context); // Last page: close
//                     } else {
//                       _controller.nextPage(
//                         duration: const Duration(milliseconds: 300),
//                         curve: Curves.easeInOut,
//                       );
//                     }
//                   },
//                   style: ElevatedButton.styleFrom(
//                     minimumSize: const Size.fromHeight(48),
//                     backgroundColor: Colors.lightBlue,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: GlobalText(
//                     currentPage == features.length - 1 ? "Finish" : "Next",
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _Feature {
//   final IconData icon;
//   final String title;
//   final String description;
//
//   const _Feature({
//     required this.icon,
//     required this.title,
//     required this.description,
//   });
// }
