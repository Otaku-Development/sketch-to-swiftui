# Sketch to SwiftUI

An iPad app that turns hand-drawn mobile UI sketches into SwiftUI code as you draw. You sketch a screen with the Apple Pencil, a YOLOv5 object detector running on-device recognises the UI components, and the app renders a live preview and generates SwiftUI code you can export as an Xcode playground.

This is the code for my MSc Artificial Intelligence dissertation at the University of Bath (2023):

> **Towards More Efficient Mobile UI Design: Automatic Code Generation from Hand-Drawn Sketches Using Deep Learning**
> Daniel Leivers — [read the dissertation (PDF)](docs/dissertation.pdf)

- **Demo video:** https://www.youtube.com/watch?v=SKGdZ3H9eyY
- **Training dataset:** https://huggingface.co/datasets/workshed/ipad-ui-sketches (133 labelled sketches, 7 classes, YOLO format)

## Repository layout

```
Capture/        Xcode project for the iPad app (SwiftUI). One app with two modes:
                - data capture: volunteers sketch an example screen and label the components,
                  and the result is uploaded to Firebase
                - drawing: live detection, SwiftUI preview, code generation and playground export
Training/       Jupyter notebooks for fetching data, training and converting to Core ML
  fetch_firebase_data-yolo.ipynb   export sketches + labels from Firebase to YOLO format, split, train YOLOv5
  fetch_firebase_data.ipynb        earlier export of per-component crops (classification experiments)
  training_experiments.ipynb       early classification experiments
  yolov8training.ipynb             YOLOv8 comparison experiment
  yolo-to-coreml.ipynb             export a trained YOLOv5 model to Core ML with NMS
  yolo/yolo/export-nms.py          YOLOv5 export script with Core ML NMS support (see Licence)
  yolo/yolo/ui_components.yaml     YOLOv5 dataset config
  yolo/yolo/hyp-exp34.yaml         hyperparameters of the best run (experiment 34)
  yolov8_components.yaml           YOLOv8 dataset config
docs/dissertation.pdf
```

## Running the iPad app

Requirements: Xcode 14.3 or later, iPadOS 16.4+, and an iPad with an Apple Pencil (the simulator works for trying out the UI).

1. Open `Capture/SketchCapture/SketchCapture.xcodeproj`. Swift Package Manager fetches the dependencies (Firebase and [Zip](https://github.com/marmelroy/Zip)).
2. **Add your own Firebase config.** The app calls `FirebaseApp.configure()` at launch, so it needs a `GoogleService-Info.plist`:
   - create a Firebase project with an iOS app, and enable **Anonymous** authentication, **Realtime Database** and **Cloud Storage**
   - download `GoogleService-Info.plist` into `Capture/SketchCapture/SketchCapture/`. It's gitignored, so it won't be committed.
   - the data-capture mode loads its example screenshots from an `examples/` folder in Cloud Storage. Upload some app screenshots there if you want to collect data. The drawing mode doesn't need them.
3. Set your own development team and bundle identifier under *Signing & Capabilities*, then build and run.

The trained detector is included as `DetectComponents8.mlpackage`. Its class list has 8 names (`segmentedControl` at index 5). The published dataset has 7 classes because `segmentedControl` was dropped from the later export (see the dataset card), so a model you train on the dataset will need its class mapping checked against `ElementClassification.swift` before you drop it into the app.

## Training a model

Download the dataset into `Training/dataset` (gitignored):

```bash
pip install -U huggingface_hub ultralytics
huggingface-cli download workshed/ipad-ui-sketches --repo-type dataset --local-dir Training/dataset
```

**YOLOv8 and later (Ultralytics package)**, from the `Training` folder:

```python
from ultralytics import YOLO

model = YOLO("yolov8s.pt")
model.train(data="yolov8_components.yaml", epochs=600, batch=4, freeze=10)
model.export(format="coreml", nms=True)
```

**YOLOv5 (as used in the dissertation)**:

```bash
cd Training/yolo/yolo
git clone https://github.com/ultralytics/yolov5
pip install -r yolov5/requirements.txt
cp export-nms.py yolov5/
# settings from the best dissertation run (experiment 34)
python yolov5/train.py --data ui_components.yaml --weights yolov5s.pt --hyp hyp-exp34.yaml \
  --epochs 1000 --batch 4 --freeze 8
```

Then follow `yolo-to-coreml.ipynb` to export a Core ML model with non-maximum suppression built in, which the app's Vision request expects.

The Firebase notebooks are how the dataset was originally built. If you collect your own data with the capture app, they read their settings from the environment:

```bash
export FIREBASE_CREDENTIALS=/path/to/service-account.json   # never commit this
export FIREBASE_DATABASE_URL=https://<project>.firebasedatabase.app/
export FIREBASE_STORAGE_BUCKET=<project>.appspot.com
```

## Tips if your model isn't performing well

Sections 5.2.3 and 7.2 of the dissertation go through the experiments in detail. In short:

- The dataset is small, so use transfer learning. Start from COCO pre-trained `yolov5s` weights and freeze the early layers instead of training from scratch. Freezing the whole backbone (10 layers) worked; freezing 8 layers and training for longer (1000 epochs) gave slightly more confident predictions.
- Augmentation helps, but don't overdo it. A high mixup value (0.8) gave the same F1 with worse precision; moderate mixup (0.5) with mosaic and a small amount of copy-paste (0.1) gave the best run (`hyp-exp34.yaml`).
- Rare classes (`switchButton`, `textField`, `tabBar`, `navigationBar`) have only 20–46 examples each, so expect them to lag behind `label`, `button` and `image`. Collecting more examples of those classes is likely to help more than further tuning.

## Licence

The code is released under the [MIT licence](LICENSE), with these exceptions:

- `Training/yolo/yolo/export-nms.py` is derived from [Ultralytics YOLOv5](https://github.com/ultralytics/yolov5) via [mshamash's Core ML NMS branch](https://github.com/mshamash/yolov5/tree/fix/coreml_export_nms_layer), and is GPL-3.0.
- `docs/dissertation.pdf` is © Daniel Leivers, all rights reserved.
- The dataset on Hugging Face is CC BY 4.0.

## Citation

```bibtex
@mastersthesis{leivers2023sketch,
  author = {Leivers, Daniel},
  title  = {Towards More Efficient Mobile {UI} Design: Automatic Code Generation from Hand-Drawn Sketches Using Deep Learning},
  school = {University of Bath},
  type   = {{MSc} dissertation},
  year   = {2023},
  url    = {https://github.com/Otaku-Development/sketch-to-swiftui}
}
```
