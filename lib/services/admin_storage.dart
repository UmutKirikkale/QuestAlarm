import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../firebase_options.dart';

/// Admin CMS — doğru Storage bucket referansı.
FirebaseStorage get adminStorage => FirebaseStorage.instanceFor(
      app: Firebase.app(),
      bucket: DefaultFirebaseOptions.admin.storageBucket,
    );
