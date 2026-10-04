package destinymatrix

// Turkish ("tr") counterparts of the Kader Matrisi text: arcana names and
// meanings, point titles, and line titles/themes. Keys mirror the English
// tables exactly; turkish_test.go fails if an English entry has no Turkish
// one.

var arcanaTR = map[int]arcanaInfo{
	1: {
		"Büyücü",
		"İrade, inisiyatif ve niyeti eyleme dönüştürme gücü. Bir şeyleri başlatmak ve soyut olanı gerçeğe dönüştürmek için yaratılmışsın.",
	},
	2: {
		"Başrahibe",
		"İç bilgi, sezgi ve sessizlikte saklı bilgelik. Kanıtlayabilmeden önce hissettiğine güvenmek senin armağanın.",
	},
	3: {
		"İmparatoriçe",
		"Yaratıcılık, bolluk ve besleyicilik. Fikirleri, insanları ve güzelliği büyütürsün; sıcaklığını dışarıya akıttığında çiçek açarsın.",
	},
	4: {
		"İmparator",
		"Düzen, otorite ve istikrarlı liderlik. Kalıcı bir düzen kurarsın; sınırlar ve planlar net olduğunda kendini en güvende hissedersin.",
	},
	5: {
		"Başrahip",
		"Gelenek, öğretme ve paylaşılan anlam. Dünyayla değerler, rehberler ve topluluğun bilgeliği aracılığıyla bağ kurarsın.",
	},
	6: {
		"Aşıklar",
		"Birlik, seçim ve zıtlıkların uyumu. Yolun, kalbini kime ve neye vermeyi seçtiğine göre şekillenir.",
	},
	7: {
		"Savaş Arabası",
		"Tutku, irade gücü ve ileriye doğru hareket. Birbiriyle yarışan güçleri dizginleyip tek bir hedefe yönelttiğinde başarırsın.",
	},
	8: {
		"Adalet",
		"Denge, hakkaniyet ve neden-sonuç ilişkisi. Her şeyi dürüstçe tartmaya ve yaptığın seçimlerin sorumluluğunu taşımaya çağrılırsın.",
	},
	9: {
		"Ermiş",
		"Yalnızlık, tefekkür ve iç ışık. En derin cevaplarını, başkalarına yol göstermeden önce düşünmek için geri çekildiğinde bulursun.",
	},
	10: {
		"Kader Çarkı",
		"Döngüler, değişim ve hareket halindeki kader. Hayatın zamanlamaya göre döner; çarkla savaşmak yerine onunla birlikte dönmeyi öğrenmek anahtardır.",
	},
	11: {
		"Güç",
		"Cesaret, sabır ve yumuşak bir ustalık. Zorlukları kaba kuvvetle değil, sakin ve şefkatli bir sebatla evcilleştirirsin.",
	},
	12: {
		"Asılan Adam",
		"Teslimiyet, yeni bir bakış açısı ve içgörüden önceki duraklama. Bıraktığında ve hayatına yeni bir açıdan baktığında büyürsün.",
	},
	13: {
		"Ölüm (Dönüşüm)",
		"Yenilenmenin önünü açan bitişler. Derin değişim için yaratılmışsın; tamamlanmış olanı bırakırsın ki daha gerçek bir şey başlayabilsin.",
	},
	14: {
		"Denge",
		"Denge, harmanlama ve sabırlı bir şifa. Uç noktaları uyumlu hale getirirsin; en iyi işini zıt enerjiler arasında bir köprü olduğunda çıkarırsın.",
	},
	15: {
		"Şeytan",
		"Arzu, bağımlılık ve gölge. Derslerin, ayartmayla yüzleşmek ve seni bağlayan şeylerden gücünü geri almakla ilgili.",
	},
	16: {
		"Kule",
		"Sahte yapıları yıkan ani sarsıntılar. Hayatındaki kırılmalar yanılsamaları söküp atar ve seni özgürleştiren bir dürüstlüğe zorlar.",
	},
	17: {
		"Yıldız",
		"Umut, ilham ve sessiz bir yenilenme. Şifa veren, yol gösteren bir ışık taşırsın ve karanlıktan geçtikten sonra en parlak halinle parlarsın.",
	},
	18: {
		"Ay",
		"Rüyalar, sezgi ve görünmeyen. Gizemin ve duyguların içinden geçerken dengeni kaybetmeden hislerine güvenmeyi öğrenirsin.",
	},
	19: {
		"Güneş",
		"Neşe, canlılık ve berrak bir kendini ifade. Gerçek benliğinin tüm haliyle görünmesine izin verdiğinde etrafına sıcaklık ve başarı saçarsın.",
	},
	20: {
		"Mahkeme",
		"Uyanış, hesaplaşma ve amacın yenilenmesi. Kendinin daha yüksek bir haline yükselmeye ve daha derin bir çağrıya yanıt vermeye çağrılırsın.",
	},
	21: {
		"Dünya",
		"Tamamlanma, bütünlük ve bütünleşme. Her şeyi tam bir döngüye taşımak ve gittiğin her yerde kendini evinde hissetmek için buradasın.",
	},
	22: {
		"Deli",
		"Sınırsız potansiyel, güven ve yeniye doğru atılan adım. Açık yürekli başlangıçları ve henüz yazılmamış bir yolun özgürlüğünü taşırsın.",
	},
}

var pointTitlesTR = map[string]string{
	"day":   "Gün / Benlik",
	"month": "Ay / Yetenekler",
	"year":  "Yıl / Soy",
	"sum":   "Amaç / Karma",

	"tl": "Maddi Kök",
	"tr": "İlişki Kökü",
	"br": "Maddi Sonuç",
	"bl": "İlişki Sonucu",

	"center": "Konfor / Öz",

	"heaven":   "Göksel Amaç",
	"earth":    "Dünyevi Amaç",
	"personal": "Kişisel Amaç",

	"arm_left_1":   "Sol Çakra (benliğe yakın)",
	"arm_left_2":   "Sol Çakra (orta)",
	"arm_left_3":   "Sol Çakra (öze yakın)",
	"arm_top_1":    "Üst Çakra (yeteneklere yakın)",
	"arm_top_2":    "Üst Çakra (orta)",
	"arm_top_3":    "Üst Çakra (öze yakın)",
	"arm_right_1":  "Sağ Çakra (soya yakın)",
	"arm_right_2":  "Sağ Çakra (orta)",
	"arm_right_3":  "Sağ Çakra (öze yakın)",
	"arm_bottom_1": "Alt Çakra (amaca yakın)",
	"arm_bottom_2": "Alt Çakra (orta)",
	"arm_bottom_3": "Alt Çakra (öze yakın)",

	"diag_tl_1": "Baba Hattı (köke yakın)",
	"diag_tl_2": "Baba Hattı (orta)",
	"diag_tl_3": "Baba Hattı (öze yakın)",
	"diag_tr_1": "Anne Hattı (köke yakın)",
	"diag_tr_2": "Anne Hattı (orta)",
	"diag_tr_3": "Anne Hattı (öze yakın)",
	"diag_br_1": "Baba Hattı (sonuca yakın)",
	"diag_br_2": "Baba Hattı (orta)",
	"diag_br_3": "Baba Hattı (öze yakın)",
	"diag_bl_1": "Anne Hattı (sonuca yakın)",
	"diag_bl_2": "Anne Hattı (orta)",
	"diag_bl_3": "Anne Hattı (öze yakın)",
}

type lineText struct {
	title string
	theme string
}

var lineTextTR = map[string]lineText{
	"personal": {
		"Kişisel",
		"Kim olduğunun yatay ekseni: doğuştan gelen benliğinin dünyayla nasıl buluştuğu ve soyunun üzerinde çalışman için sana neler bıraktığı.",
	},
	"spiritual": {
		"Manevi",
		"Anlamın dikey ekseni: taşıdığın yetenekler ve onların hizmet etmesi gereken yüksek amaç ya da karmik görev.",
	},
	"money": {
		"Para / Maddi",
		"Kaynakların inen köşegeni: bollukla ve emekle kurduğun ilişki ve zamanla ulaştığın maddi sonuçlar.",
	},
	"love": {
		"Aşk / İlişki",
		"Kalbin yükselen köşegeni: nasıl bağ kurduğun, birliktelikte ne aradığın ve olgunlaştıkça içinde serpildiğin ilişkiler.",
	},
	"maleGeneration": {
		"Erkek Soy Hattı",
		"Baba köşegeni (sol üstten sağ alta): baba tarafından aktarılan yetenekler, borçlar ve dersler.",
	},
	"femaleGeneration": {
		"Kadın Soy Hattı",
		"Anne köşegeni (sağ üstten sol alta): anne tarafından aktarılan armağanlar, yaralar ve karmik kalıplar.",
	},
}
