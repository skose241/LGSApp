INSERT INTO Dersler (dersAdi, oturum, siraNo) VALUES
    (N'Türkçe',                               N'sozel',   1),
    (N'T.C. İnkılap Tarihi ve Atatürkçülük',  N'sozel',   2),
    (N'Din Kültürü ve Ahlak Bilgisi',         N'sozel',   3),
    (N'İngilizce',                            N'sozel',   4),
    (N'Matematik',                            N'sayisal', 5),
    (N'Fen Bilimleri',                        N'sayisal', 6)

GO

INSERT INTO Konular (dersID, konuAdi, siraNo)
SELECT d.dersID, k.konuAdi, k.siraNo
FROM Dersler d
INNER JOIN(
    SELECT N'Türkçe' AS dersAdi, N'Sözcükte ve Söz Gruplarında Anlam' AS konuAdi, 1 AS siraNo
    UNION ALL SELECT N'Türkçe', N'Fiilimsiler',              2
    UNION ALL SELECT N'Türkçe', N'Cümlenin Ögeleri',         3
    UNION ALL SELECT N'Türkçe', N'Deyimler ve Atasözleri',   4

    UNION ALL SELECT N'Matematik', N'Çarpanlar ve Katlar',   1
    UNION ALL SELECT N'Matematik', N'Üslü İfadeler',         2
    UNION ALL SELECT N'Matematik', N'Kareköklü İfadeler',    3

    UNION ALL SELECT N'Fen Bilimleri', N'Mevsimler ve İklim',    1
    UNION ALL SELECT N'Fen Bilimleri', N'DNA ve Genetik Kod',    2

    UNION ALL SELECT N'T.C. İnkılap Tarihi ve Atatürkçülük', N'Bir Kahraman Doğuyor', 1
    UNION ALL SELECT N'T.C. İnkılap Tarihi ve Atatürkçülük', N'Milli Uyanış',         2

    UNION ALL SELECT N'İngilizce', N'Friendship',            1
    UNION ALL SELECT N'İngilizce', N'Teen Life',             2

    UNION ALL SELECT N'Din Kültürü ve Ahlak Bilgisi', N'Kader İnancı',       1
    UNION ALL SELECT N'Din Kültürü ve Ahlak Bilgisi', N'Zekat ve Sadaka',    2
) AS k
ON k.dersAdi = d.dersAdi 

GO

INSERT INTO Ayarlar (ayarAnahtar, ayarDeger) VALUES
    (N'gunlukSoruSayisi',          N'1'),
    (N'puanDogruCevap',            N'5'),
    (N'puanSoruYukleme',           N'3'),
    (N'puanCozumYazma',            N'5'),
    (N'cozumEsikCevapSayisi',      N'5'),
    (N'cozumEsikYanlisOrani',      N'60'),
    (N'aciklamaMinKarakter',       N'30'),
    (N'soruUretimAktifMi',         N'1')

GO