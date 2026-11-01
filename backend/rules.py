LABEL_ID = {
    "straight": "Lurus (Straight)",
    "wavy": "Bergelombang (Wavy)",
    "curly": "Keriting (Curly)",
    "kinky": "Kinky (Coily)",
}

DISCLAIMER = (
    "Rekomendasi bersifat umum dan bukan pengganti konsultasi dokter kulit/trikolog. "
    "Penanda [1]-[3] merujuk ke daftar Referensi; aturan tanpa penanda disusun dari praktik perawatan rambut umum "
    "dan belum divalidasi oleh pakar."
)

REFERENSI = (
    "[1] American Academy of Dermatology (AAD), Curly hair care:\n"
    "https://www.aad.org/public/everyday-care/hair-scalp-care/hair/curly-hair-care\n"
    "[2] AAD, Tips for healthy hair:\n"
    "https://www.aad.org/public/everyday-care/hair-scalp-care/hair/healthy-hair-tips\n"
    "[3] HealthDay (merangkum panduan AAD), What is dandruff & how is it treated:\n"
    "https://Drugs.com/news/dandruff-treated-116614.html\n"
    "Aturan tanpa penanda [n] disusun dari praktik perawatan umum, bukan dari sumber di atas."
)

# fakta f: t = jenis rambut (hasil CNN), s = kulit kepala, c = kondisi rambut, k = set keluhan
# format: (id, judul, kondisi, isi)
RULES = [
    # ---------------- LURUS ----------------
    ("lurus-keramas", "Keramas",
     lambda f: f["t"] == "straight",
     "Rambut lurus mudah berminyak karena minyak alami dari kulit kepala gampang meluncur sampai ke ujung. "
     "Keramas sesuai seberapa cepat rambut terasa berminyak atau kotor [2]; pada rambut yang cepat berminyak, "
     "itu bisa tiap 1-2 hari. Fokuskan shampoo ke kulit kepala lalu bilas sampai bersih supaya tidak ada sisa "
     "produk yang bikin rambut lepek."),
    ("lurus-kondisioner", "Kondisioner & pelembap",
     lambda f: f["t"] == "straight",
     "Untuk rambut halus atau lurus, conditioner cukup dioleskan di bagian ujung rambut [2]. Hindari minyak rambut "
     "atau butter yang tebal di dekat akar karena membuat rambut cepat lepek dan kempis. Untuk ujung yang kering, "
     "cukup serum atau leave-in yang ringan."),
    ("lurus-menata", "Mengeringkan & menata",
     lambda f: f["t"] == "straight",
     "Keringkan dengan menyerap air memakai handuk atau kaos secara lembut, jangan digosok keras [2]. Biarkan rambut "
     "agak kering dulu sebelum disisir [2]. Untuk menambah volume, keringkan bagian akar dengan hair dryer sambil "
     "mengangkat rambut. Panas berlebih merusak semua tipe rambut, jadi lindungi rambut dari panas [2]."),
    ("lurus-hindari", "Yang sebaiknya dihindari",
     lambda f: f["t"] == "straight",
     "Hindari air keramas yang terlalu panas dan terlalu sering menyentuh rambut karena minyak dari tangan mudah "
     "menempel ke helai rambut. Jangan menyisir terlalu keras saat rambut masih basah [2]."),

    # ---------------- BERGELOMBANG ----------------
    ("wavy-keramas", "Keramas",
     lambda f: f["t"] == "wavy",
     "Rambut bergelombang gampang frizz dan pola gelombangnya mudah rusak. Keramas sekitar 2-3 hari sekali sebagai "
     "patokan awal, lalu sesuaikan dengan seberapa cepat rambut berminyak atau kotor [2]. Pilih shampoo yang lembut "
     "dan hindari mengucek rambut kuat-kuat. Catatan: aku belum menemukan sumber khusus untuk rambut bergelombang, "
     "jadi panduan tipe ini berbasis praktik umum."),
    ("wavy-kondisioner", "Kondisioner & pelembap",
     lambda f: f["t"] == "wavy",
     "Gunakan conditioner ringan di pertengahan sampai ujung, lalu leave-in atau mousse yang ringan. Pilih formula "
     "ringan dengan minyak alami (misalnya argan atau kelapa). Terlalu banyak produk berat membuat gelombang jadi "
     "lepek dan kehilangan bentuk."),
    ("wavy-menata", "Detangle, mengeringkan & menata",
     lambda f: f["t"] == "wavy",
     "Urai kusut saat rambut basah dan penuh conditioner memakai sisir gigi lebar atau jari. Keringkan dengan handuk "
     "microfiber atau kaos dengan cara ditekan, jangan digosok [2]. Bentuk gelombang dengan teknik scrunch (diremas "
     "pelan ke arah atas), lalu biarkan kering alami atau pakai diffuser dengan suhu rendah."),
    ("wavy-mingguan", "Perawatan mingguan",
     lambda f: f["t"] == "wavy",
     "Tambahkan hair mask atau deep conditioning sekitar seminggu sekali untuk menjaga kelembapan dan mengurangi "
     "frizz, terutama kalau rambut sering terpapar panas matahari atau alat styling."),
    ("wavy-hindari", "Yang sebaiknya dihindari",
     lambda f: f["t"] == "wavy",
     "Hindari menyisir saat rambut kering karena membuatnya mengembang, dan batasi catok atau hair dryer panas, "
     "karena panas berlebih bisa merusak rambut [2]."),

    # ---------------- KERITING ----------------
    ("curly-keramas", "Keramas",
     lambda f: f["t"] == "curly",
     "Rambut keriting cenderung lebih kering dan rentan patah dibanding tipe lain [1]. Rambut keriting tidak perlu "
     "dicuci setiap hari, bahkan tidak harus tiap minggu [1]. AAD menyebut rambut kering atau keriting dikeramas sesuai "
     "kebutuhan, setidaknya sekali tiap 2-3 minggu [2]. Pilih shampoo pelembap yang diformulasikan untuk rambut "
     "keriting [1]. Banyak orang memilih yang bebas sulfat, tetapi itu preferensi, bukan syarat dari AAD."),
    ("curly-kondisioner", "Kondisioner & pelembap",
     lambda f: f["t"] == "curly",
     "Untuk rambut kering atau keriting, oleskan conditioner di seluruh panjang rambut [2] dan jaga rambut tetap "
     "lembap [1]. Kalau rambut sangat kering atau susah diurai sebelum keramas, conditioner boleh dipakai sebelum "
     "keramas [1]. Deep conditioning atau hair mask sekitar seminggu sekali adalah patokan umum (bukan dari sumber)."),
    ("curly-menata", "Detangle & menata",
     lambda f: f["t"] == "curly",
     "Urai kusut di antara keramas dengan membasahi rambut sampai rata, memberi leave-in conditioner, lalu mengurai "
     "dengan jari atau sisir gigi lebar [1]. Waktu menyisir yang baik untuk rambut tebal dan keriting adalah di kamar "
     "mandi sebelum conditioner dibilas [2]. Setelah itu oleskan curl cream atau gel pada rambut basah, lalu remas "
     "pelan ke arah atas (scrunch) untuk membentuk keriting."),
    ("curly-mengeringkan", "Mengeringkan",
     lambda f: f["t"] == "curly",
     "Keringkan dengan menyerap air memakai handuk atau kaos secara lembut, bukan menggosok keras [2]. Biarkan kering "
     "alami atau pakai diffuser suhu rendah, dan jangan disentuh atau disisir saat masih setengah kering supaya tidak "
     "frizz. Panas dan sinar UV matahari bisa mengeringkan rambut keriting [1]."),
    ("curly-hindari", "Yang sebaiknya dihindari",
     lambda f: f["t"] == "curly",
     "Jangan menyisir saat rambut kering dan batasi penggunaan catok, karena panas berlebih merusak rambut [2]. "
     "Lindungi rambut dari terik matahari [1]. AAD juga menyarankan merawat rambut saat tidur, misalnya dengan "
     "kuncir longgar di atas kepala atau kepang longgar untuk mengurangi gesekan dengan sarung bantal [1]. "
     "Sarung bantal satin atau bonnet adalah praktik umum, bukan dari sumber."),


    # ---------------- KINKY / COILY ----------------
    ("kinky-keramas", "Keramas",
     lambda f: f["t"] == "kinky",
     "Rambut kinky/coily (sangat keriting) sangat rentan kering dan patah [1]. Rambut seperti ini tidak perlu dicuci "
     "tiap hari, bahkan tidak harus tiap minggu [1]. Keramas sesuai kebutuhan, setidaknya sekali tiap 2-3 minggu "
     "untuk rambut kering atau bertekstur [2], dengan shampoo pelembap yang diformulasikan untuk rambut keriting [1]."),
    ("kinky-pelembap", "Pelembap berlapis",
     lambda f: f["t"] == "kinky",
     "Jaga kelembapan rambut secara rutin karena rambut keriting lebih kering dibanding tipe lain [1]. Pola yang "
     "populer: leave-in berbasis air, lalu minyak (misalnya kelapa, jojoba, atau argan), lalu krim untuk mengunci "
     "kelembapan. Deep conditioning sekitar seminggu sekali. Urutan dan frekuensi ini praktik umum, bukan dari sumber."),
    ("kinky-detangle", "Detangle dengan sabar",
     lambda f: f["t"] == "kinky",
     "Urai kusut dengan membasahi rambut sampai rata, memberi leave-in conditioner, lalu mengurai memakai jari atau "
     "sisir gigi lebar [1]. Bagi rambut menjadi beberapa bagian dan mulai dari ujung naik ke akar. Jangan ditarik paksa."),
    ("kinky-pelindung", "Gaya pelindung (protective style)",
     lambda f: f["t"] == "kinky",
     "Gaya seperti kepang atau twist yang longgar bisa mengurangi gesekan dan kusut. Jangan terlalu kencang karena "
     "akan menarik akar rambut, dan lepas serta rawat rambut secara berkala. (Praktik umum, bukan dari sumber.)"),
     ("kinky-hindari", "Yang sebaiknya dihindari",
     lambda f: f["t"] == "kinky",
     "Hindari panas berlebih (catok, hair dryer panas) [2] dan paparan matahari berlebihan [1], serta menyisir saat "
     "rambut kering. Rawat rambut saat tidur: AAD menyarankan kuncir longgar di atas kepala atau kepang longgar "
     "untuk mengurangi gesekan dengan sarung bantal [1]. Sarung bantal satin atau bonnet adalah praktik umum, "
     "bukan dari sumber."),

    # ---------------- KULIT KEPALA ----------------
    ("kulit-berminyak", "Kulit kepala berminyak",
     lambda f: f["s"] == "Berminyak",
     "Fokuskan shampoo ke kulit kepala dengan pijatan lembut memakai ujung jari (bukan kuku), lalu bilas sampai bersih. "
     "Conditioner cukup di batang dan ujung. Hindari memijat produk berminyak ke kulit kepala dan jangan keramas "
     "dengan air terlalu panas."),
    ("kulit-kering", "Kulit kepala kering",
     lambda f: f["s"] == "Kering",
     "Pakai shampoo yang lembut dan melembapkan, hindari air panas, dan jangan keramas berlebihan. "
     "Kalau kulit kepala gatal dan bersisik, bisa jadi bukan sekadar kering, jadi lihat juga panduan untuk ketombe."),

    # ---------------- KONDISI RAMBUT ----------------
    ("kondisi-rusak", "Rambut rusak / bercabang",
     lambda f: f["c"] == "Rusak/bercabang",
     "Kurangi alat panas karena panas berlebih merusak rambut [2], dan pakai pelindung panas bila harus styling. "
     "Gunakan masker penguat secara berkala. Potong ujung rambut tiap 6-8 minggu supaya belahan tidak merambat ke "
     "atas, dan sisir dengan hati-hati mulai dari ujung."),
    ("kondisi-warna", "Rambut diwarnai / proses kimia",
     lambda f: f["c"] == "Diwarnai/proses kimia",
     "Pakai shampoo untuk rambut berwarna, masker pelembap rutin, dan air suam-suam kuku saat keramas supaya warna "
     "tidak cepat pudar. Beri jeda antar proses kimia, dan konsultasikan ke salon kalau rambut terasa sangat rapuh."),

    # ---------------- KELUHAN ----------------
    ("keluhan-frizz", "Keluhan frizz",
     lambda f: "Frizz" in f["k"],
     "Pakai leave-in atau serum pelembap dan kurangi gesekan: jangan menggosok rambut dengan handuk [2] dan jangan "
     "menyisir saat kering. Hindari shampoo yang terlalu keras. Semakin sedikit rambut disentuh saat mengering, "
     "semakin sedikit frizz."),
    ("keluhan-rontok", "Keluhan rontok",
     lambda f: "Rontok" in f["k"],
     "Rontok ringan setiap hari itu normal. Kurangi tarikan (ikat rambut terlalu kencang) dan panas berlebih. "
     "Kalau rontok berlebihan, rambut tampak menipis, atau berlangsung berminggu-minggu, konsultasikan ke dokter kulit."),
    ("keluhan-ketombe", "Keluhan ketombe",
     lambda f: "Ketombe" in f["k"],
     "Ketombe bukan disebabkan oleh kurang bersih [3]. Ketombe ringan sering membaik dengan keramas teratur; kalau "
     "membandel, pakai shampoo ketombe yang mengandung salah satu bahan aktif: zinc pyrithione, salicylic acid, "
     "sulfur, selenium sulfide, ketoconazole, atau coal tar [3]. Kalau satu produk tidak berhasil, coba gantian "
     "dengan bahan aktif lain, dan sebagian produk perlu didiamkan sekitar 5-10 menit sebelum dibilas [3]. Lindungi "
     "kulit kepala dari matahari [3]. Kalau tidak membaik, konsultasi ke dokter kulit."),
    ("keluhan-kusam", "Keluhan kusam",
     lambda f: "Kusam" in f["k"],
     "Gunakan clarifying shampoo sesekali (sekitar 2-4 minggu sekali) untuk membersihkan sisa produk, lalu lanjutkan "
     "dengan conditioner atau masker pelembap supaya rambut tidak jadi kering."),
    ("keluhan-patah", "Keluhan kering / mudah patah",
     lambda f: "Kering/mudah patah" in f["k"],
     "Tambahkan deep conditioning sekitar seminggu sekali, kurangi panas [2] dan tarikan saat menyisir, serta rapikan "
     "ujung rambut secara berkala. Sisir dengan sisir gigi lebar mulai dari ujung."),

    # ---------------- KOMBINASI ----------------
    ("kombinasi-ikal-minyak", "Ikal/kinky dengan kulit kepala berminyak",
     lambda f: f["t"] in ("curly", "kinky") and f["s"] == "Berminyak",
     "Batang rambut tetap perlu pelembap walaupun kulit kepala berminyak. Bersihkan kulit kepala lebih teliti saat "
     "keramas, tetapi jangan melewatkan conditioner di batang dan ujung."),
    ("kombinasi-ikal-rusak", "Ikal/kinky dengan rambut rusak atau diwarnai",
     lambda f: f["t"] in ("curly", "kinky") and f["c"] in ("Rusak/bercabang", "Diwarnai/proses kimia"),
     "Selingi treatment protein secara berkala dengan deep conditioning pelembap agar keseimbangan protein dan "
     "kelembapan terjaga."),
    ("kombinasi-ikal-ketombe", "Ikal/kinky dengan ketombe",
     lambda f: f["t"] in ("curly", "kinky") and "Ketombe" in f["k"],
     "Untuk rambut keriting atau kasar, shampoo ketombe dipakai sekitar seminggu sekali (di luar itu keramas "
     "sesuai kebutuhan) dan dipijatkan ke kulit kepala, bukan ke batang rambut, karena bahan aktifnya cenderung "
     "mengeringkan rambut [3]. Setelah itu lembapkan batang rambut dengan conditioner."),
]


def get_recommendations(f):
    out = []
    for rid, title, cond, txt in RULES:
        if cond(f):
            out.append({"id": rid, "kind": "perawatan", "title": title, "text": txt})
    # daftar referensi ditaruh paling akhir (tampil di akhir Panduan Perawatan)
    out.append({"id": "referensi", "kind": "perawatan", "title": "Referensi", "text": REFERENSI})
    return out