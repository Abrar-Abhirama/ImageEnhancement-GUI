# IF4073 - Image Enhancement GUI

Aplikasi MATLAB GUI untuk perbaikan kualitas citra digital menggunakan berbagai teknik transformasi intensitas, histogram equalization, histogram matching/specification, dan image filtering.

## Deskripsi Singkat

Program ini menyediakan antarmuka grafis (GUI) untuk melakukan operasi peningkatan kualitas citra (*image enhancement*), meliputi:

- **Intensity Transformation**: Mentransformasi intensitas melalui Brightness Adjustment, Contrast Correction, Negative, Log, Power-law (Gamma), dan Contrast Stretching.
- **Histogram Equalization**: : Meningkatkan kontras citra dengan meratakan distribusi intensitas berdasarkan histogram.
- **Histogram Matching/Specification**: Menyesuaikan distribusi intensitas citra dengan histogram citra referensi.
- **Image Filtering**: Meningkatkan atau menonjolkan karakteristik citra menggunakan filter Linear (Gaussian, Mean, Sharpen, Sobel, Laplacian, Custom) dan Non-Linear (Median).

## Dependensi

### MATLAB Toolbox
- **MATLAB R2021a** atau lebih baru
- **Image Processing Toolbox** - diperlukan untuk fungsi pemrosesan citra dasar

### Struktur Folder Project
```
ImageEnhancement-GUI/
├── src/
│   ├── analysis/              # Modul analisis citra
│   │   ├── histogram/      	# Fungsi histogram
│   │   │   ├── computeCDF.m
│   │   │   ├── computeHistogram.m
│   │   │   ├── computeHistogramGrayscale.m
│   │   │   └── computeHistogramRGB.m
│   │   └── analyzeImage.m
│   ├── enhancement/            # Modul teknik enhancement
│   │   ├── IntensityTransformation/
│   │   │   └── intensityTransform.m
│   │   ├── HistogramEqualization/
│   │   │   └── histogramEqualization.m
│   │   ├── HistogramSpecification/
│   │   │   └── *.m
│   │   ├── Filtering/
│   │   │   └── *.m
│   │   └── applyEnhancement.m
│   ├── gui/                   # Antarmuka pengguna
│   │   ├── ImageEnhancementApp.m
│   │   └── imageEnhancementGUI.m
│   ├── utils/             	# Fungsi utilitas
│   │   ├── computeHistogramChannel.m
│   │   ├── computeHistogramLocal.m
│   │   ├── computeImageStats.m
│   │   └── visualizeEnhancementComparison.m
│   └── test/             	# Skrip pengujian
├── startup.m              	# Inisialisasi path
└── README.md
```

## Cara Menjalankan Program

### Prasyarat
1. Pastikan MATLAB sudah terinstal (R2021a atau lebih baru)
2. Pastikan Image Processing Toolbox sudah terinstal

### Langkah Menjalankan

1. Buka MATLAB
2. Navigasi ke folder project:
   ```matlab
   cd 'C:\Users\Acer\Downloads\ImageEnhancement-GUI\src\gui'
   ```
3. Jalankan GUI menggunakan salah satu cara berikut:

   **Cara 1: Menggunakan fungsi launcher (Direkomendasikan)**
   ```matlab
   imageEnhancementGUI
   ```

   **Cara 2: Langsung membuat instance aplikasi**
   ```matlab
   app = ImageEnhancementApp;
   ```

## Metode yang Tersedia

### 1. Intensity Transformation

| Metode | Deskripsi | Rumus |
|--------|-----------|-------|
| Negative | Inversi warna citra | s = 255 - r |
| Log | Transformasi logaritmik (memperjelas dark regions) | s = c × (log(1+r) / log(256)) × 255 |
| Power (Gamma) | Transformasi power-law | s = c × (r/255)^γ × 255 |
| Contrast Stretching | Perlebar dynamic range | s = (r - rmin) / (rmax - rmin) × 255 |
| Brightening | Pengaturan kecerahan | s = r + brightness × 255 |
| Contrast Correction | Pengaturan kontras terhadap mean | s = c × (r - mean) + mean |

**Parameter:**
- `c` (constant): Konstanta pengali (default: 1)
- `gamma`: Eksponen untuk power-law (γ < 1: brightening, γ > 1: darkening)
- `brightness`: Offset kecerahan (range: -1 sampai 1)
- `contrast`: Faktor kontras (c < 1: mengurangi, c > 1: meningkatkan)

### 2. Histogram Equalization

| Mode | Deskripsi |
|------|-----------|
| Global | Equalization pada seluruh channel secara independen |
| HSV | Equalization pada channel Value (kecerahan) saja |
| YCbCr | Equalization pada channel Luminance (Y) saja |

Mode HSV dan YCbCr lebih disarankan untuk citra berwarna karena mempertahankan informasi warna (hue) sambil meningkatkan kontras.

### 3. Histogram Matching/Specification

Histogram Matching/Specification memungkinkan penyesuaian histogram citra input agar menyerupai histogram referensi tertentu. Metode ini berguna untuk:
- Menstandarisasi pencahayaan antar citra
- Menghasilkan efek visual yang konsisten
- Mencocokkan karakteristik warna antar citra

**Parameter:**
- Reference image: Citra referensi yang histogramnya akan dijadikan target

### 4. Image Filtering

#### Filter Linear
| Filter | Deskripsi |
|--------|-----------|
| Mean/Average/Box | Filter rata-rata untuk smoothing |
| Gaussian | Filter Gaussian untuk smoothing dengan bobot sentral |
| Sharpen | Filter penajaman untuk meningkatkan detail |
| Sobel   | Deteksi tepi |
| Laplacian | Deteksi tepi menggunakan Laplacian |
| Custom | Filter dengan kernel/mask yang ditentukan oleh pengguna |

#### Filter Non-Linear
| Filter | Deskripsi |
|--------|-----------|
| Median | Filter median untuk noise removal tanpa blur |

**Parameter:**
- `size`: Ukuran kernel/filter (default: 3)
- `sigma`: Standar deviasi untuk Gaussian filter

## Cara Penggunaan

### Memuat Citra
1. Klik **"Load Image"** pada panel kiri GUI
2. Pilih file citra dari dialog yang muncul
3. Citra input dan histogramnya akan ditampilkan secara otomatis di panel kanan

### Memilih Metode
1. Pilih metode pada dropdown **"Method"**:
   - **Intensity Transformation** - Transformasi intensitas
   - **Histogram Equalization** - Penyeimbangan histogram
   - **Histogram Matching** - Pencocokan histogram dengan referensi
   - **Linear Filtering** - Filter linear
   - **Median Filtering** - Filter median
2. Panel **Parameters** akan menampilkan sub-metode dan parameter yang sesuai

### Mengatur Parameter
1. Pilih sub-metode dari dropdown yang tersedia
2. Atur parameter melalui slider atau edit field sesuai kebutuhan
3. Parameter yang tersedia bergantung pada metode yang dipilih

### Menjalankan Enhancement
1. Klik tombol **"Enhance"**
2. Citra hasil dan histogram output akan ditampilkan di panel kanan
3. Panel **Status** akan menampilkan informasi metode dan parameter yang digunakan

### Menyimpan atau Menyalin Hasil
1. Pada gambar input atau hasil, klik ikon **tiga titik (...)** yang ada di atas gambar
2. Pilih **"Save"** untuk menyimpan gambar ke perangkat
3. Pilih **"Copy"** untuk menyalin gambar ke clipboard sehingga dapat ditempelkan ke aplikasi lain

### Reset atau Mengulang
1. Klik tombol **"Reset"** untuk kembali ke kondisi awal
2. Ubah metode atau parameter untuk melakukan percobaan lain