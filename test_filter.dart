void main() {
  final role = "Railway Worker";
  final workerType = "Attendant";
  final designation = "Test";

  final roleLower = role.toLowerCase();
  final wtLower = workerType.toLowerCase();
  final desigLower = designation.toLowerCase();

  final isFieldWorker = roleLower.contains('janitor') || 
                       roleLower.contains('attendant') ||
                       roleLower.contains('worker') ||
                       roleLower.contains('cleaner') ||
                       roleLower.contains('safai') ||
                       roleLower.contains('field') ||
                       wtLower.contains('janitor') || 
                       wtLower.contains('attendant') ||
                       wtLower.contains('cleaner') ||
                       desigLower.contains('janitor') || 
                       desigLower.contains('attendant') || 
                       desigLower.contains('worker') ||
                       desigLower.contains('cleaner') ||
                       desigLower.contains('safai');
  
  print('isFieldWorker: \$isFieldWorker');
}
