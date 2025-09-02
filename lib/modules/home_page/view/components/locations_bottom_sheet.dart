// import 'package:car_route/modules/global/widgets/global_text.dart';
// import 'package:flutter/material.dart';
// import 'package:geocoding/geocoding.dart';
//
// class LocationsBottomSheet extends StatelessWidget {
//   final List<Location> locations;
//   final Function(Location) onSetMap;
//   final Function(Location) onSelectLocation;
//
//   const LocationsBottomSheet({
//     super.key,
//     required this.locations,
//     required this.onSetMap,
//     required this.onSelectLocation,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       height: 400,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Center(
//             child: ElevatedButton.icon(
//               onPressed: () {
//                 if (locations.isNotEmpty) {
//                   Navigator.pop(context);
//                   onSetMap(locations[0]);
//                 }
//               },
//               icon: const Icon(Icons.map,color: Colors.lightBlue,),
//               label: const GlobalText("Set On Map"),
//             ),
//           ),
//           const SizedBox(height: 16),
//           const GlobalText(
//             "Select a Location",
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//           ),
//           const SizedBox(height: 8),
//           Expanded(
//             child: ListView.builder(
//               itemCount: locations.length,
//               itemBuilder: (context, index) {
//                 final location = locations[index];
//                 return FutureBuilder<String>(
//                   future: CustomLatLong(
//                           lat: location.latitude, long: location.longitude)
//                       .getAddressFromLatLng(),
//                   builder: (context, snapshot) {
//                     final address = snapshot.data ?? "Loading address...";
//                     return ListTile(
//                       leading: const Icon(Icons.location_on),
//                       title: GlobalText(address),
//                       onTap: () {
//                         Navigator.pop(context);
//                         onSelectLocation(location);
//                       },
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
