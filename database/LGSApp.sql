CREATE TABLE Oturumlar(
    oturumID        INT IDENTITY(1,1) NOT NULL,
    kullaniciID     INT               NOT NULL,
    sessionToken    NVARCHAR(255)     NOT NULL,
    girisTarihi     DATETIME          NOT NULL DEFAULT GETDATE(),
    sonGoruldu      DATETIME          NULL,
    aktifMi         BIT               NOT NULL DEFAULT 1,

    CONSTRAINT PK_Oturumlar PRIMARY KEY (oturumID),
    CONSTRAINT FK_Oturumlar_Kullanicilar FOREIGN KEY (kullaniciID) REFERENCES Kullanicilar(kullaniciID),
    CONSTRAINT UQ_Oturumlar_token UNIQUE (sessionToken)
)

GO

CREATE TABLE HataLog(
    hataID          INT IDENTITY(1,1) NOT NULL,
    sayfa           NVARCHAR(100)     NULL,
    islem           NVARCHAR(100)     NULL,
    mesaj           NVARCHAR(MAX)     NULL,
    detay           NVARCHAR(MAX)     NULL,
    eklenmeTarihi   DATETIME          NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_HataLog PRIMARY KEY (hataID)
)

GO

CREATE TABLE Dersler(
    dersID          INT IDENTITY(1,1) NOT NULL,
    dersAdi         NVARCHAR(50)      NOT NULL,
    oturum          NVARCHAR(10)      NOT NULL,
    siraNo          INT               NOT NULL DEFAULT 0,
    aktifMi         BIT               NOT NULL DEFAULT 1,
    uretimSikligi   TINYINT           NOT NULL DEFAULT 1,

    CONSTRAINT PK_Dersler PRIMARY KEY (dersID),
    CONSTRAINT UQ_Dersler_dersAdi UNIQUE (dersAdi),
    CONSTRAINT CK_Dersler_oturum CHECK (oturum IN (N'sozel', N'sayisal'))
)

GO

CREATE TABLE Konular(
    konuID          INT IDENTITY(1,1) NOT NULL,
    dersID          INT               NOT NULL,
    konuAdi         NVARCHAR(150)     NOT NULL,
    siraNo          INT               NOT NULL DEFAULT 0,
    aktifMi         BIT               NOT NULL DEFAULT 1,

    CONSTRAINT PK_Konular PRIMARY KEY (konuID),
    CONSTRAINT FK_Konular_Dersler FOREIGN KEY (dersID) REFERENCES Dersler(dersID),
    CONSTRAINT UQ_Konular_dersKonu UNIQUE (dersID, konuAdi)
)

GO

CREATE TABLE Kullanicilar(
    kullaniciID     INT IDENTITY(1,1) NOT NULL,
    kullaniciAdi    NVARCHAR(50)      NOT NULL,
    adSoyad         NVARCHAR(100)     NULL,
    sifreHash       NVARCHAR(255)     NOT NULL,
    rol             TINYINT      NOT NULL DEFAULT 3,
    bransDersID     INT               NULL,
    puan            INT               NOT NULL DEFAULT 0,
    avatar          NVARCHAR(255)     NULL,
    kayitTarihi     DATETIME          NOT NULL DEFAULT GETDATE(),
    sonGirisTarihi  DATETIME          NULL,
    aktifMi         BIT               NOT NULL DEFAULT 1,

    CONSTRAINT PK_Kullanicilar PRIMARY KEY (kullaniciID),
    CONSTRAINT UQ_Kullanicilar_kullaniciAdi UNIQUE (kullaniciAdi),
    CONSTRAINT FK_Kullanicilar_Dersler FOREIGN KEY (bransDersID) REFERENCES Dersler(dersID),
    CONSTRAINT CK_Kullanicilar_rol CHECK (rol IN (1,2,3,4))
)

GO

CREATE TABLE Sorular(
    soruID          INT IDENTITY(1,1) NOT NULL,
    kullaniciID     INT               NOT NULL,
    dersID          INT               NOT NULL,
    konuID          INT               NULL,
    soruMetni       NVARCHAR(MAX)     NULL,
    soruGorsel      NVARCHAR(255)     NULL,
    secenekA        NVARCHAR(500)     NULL,
    secenekB        NVARCHAR(500)     NULL,
    secenekC        NVARCHAR(500)     NULL,
    secenekD        NVARCHAR(500)     NULL,
    dogruCevap      NCHAR(1)          NOT NULL,
    aciklama        NVARCHAR(MAX)     NULL,
    kaynak          TINYINT      NOT NULL,
    yayinTarihi     DATE              NULL,
    yayinlandiMi    BIT               NOT NULL DEFAULT 1,
    cozumGerekmiyor BIT               NOT NULL DEFAULT 0,
    olusturmaTarihi DATETIME          NOT NULL DEFAULT GETDATE(),
    aktifMi         BIT               NOT NULL DEFAULT 1,

    CONSTRAINT PK_Sorular PRIMARY KEY (soruID),
    CONSTRAINT FK_Sorular_Kullanicilar FOREIGN KEY (kullaniciID) REFERENCES Kullanicilar(kullaniciID),
    CONSTRAINT FK_Sorular_Dersler FOREIGN KEY (dersID) REFERENCES Dersler(dersID),
    CONSTRAINT FK_Sorular_Konular FOREIGN KEY (konuID) REFERENCES Konular(konuID),
    CONSTRAINT CK_Sorular_dogruCevap CHECK (dogruCevap IN (N'A', N'B', N'C', N'D')),
    CONSTRAINT CK_Sorular_kaynak CHECK (kaynak IN (2,3,4)),
    CONSTRAINT CK_Sorular_icerik CHECK (soruMetni IS NOT NULL OR soruGorsel IS NOT NULL)
)

GO

CREATE INDEX IX_Sorular_ders ON Sorular (dersID, aktifMi)

GO

CREATE INDEX IX_Sorular_yayin ON Sorular (yayinTarihi, yayinlandiMi)

GO

CREATE INDEX IX_Sorular_kullanici ON Sorular (kullaniciID)

GO

CREATE TABLE Cevaplar(
    cevapID         INT IDENTITY(1,1) NOT NULL,
    soruID          INT               NOT NULL,
    kullaniciID     INT               NOT NULL,
    verilenCevap    NCHAR(1)          NOT NULL,
    dogruMu         BIT               NOT NULL,
    cevapTarihi     DATETIME          NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_Cevaplar PRIMARY KEY (cevapID),
    CONSTRAINT FK_Cevaplar_Sorular FOREIGN KEY (soruID) REFERENCES Sorular(soruID),
    CONSTRAINT FK_Cevaplar_Kullanicilar FOREIGN KEY (kullaniciID) REFERENCES Kullanicilar(kullaniciID),
    CONSTRAINT UQ_Cevaplar_soruKullanici UNIQUE (soruID, kullaniciID),
    CONSTRAINT CK_Cevaplar_verilenCevap CHECK (verilenCevap IN (N'A', N'B', N'C', N'D'))
)

GO

CREATE TABLE Cozumler(
    cozumID         INT IDENTITY(1,1) NOT NULL,
    soruID          INT               NOT NULL,
    kullaniciID     INT               NULL,
    cozumTipi       TINYINT      NOT NULL,
    cozumMetni      NVARCHAR(MAX)     NULL,
    cozumGorsel     NVARCHAR(255)     NULL,
    olusturmaTarihi DATETIME          NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_Cozumler PRIMARY KEY (cozumID),
    CONSTRAINT FK_Cozumler_Sorular FOREIGN KEY (soruID) REFERENCES Sorular(soruID),
    CONSTRAINT FK_Cozumler_Kullanicilar FOREIGN KEY (kullaniciID) REFERENCES Kullanicilar(kullaniciID),
    CONSTRAINT CK_Cozumler_cozumTipi CHECK (cozumTipi IN (2,3,4)),
    CONSTRAINT CK_Cozumler_icerik CHECK (cozumMetni IS NOT NULL OR cozumGorsel IS NOT NULL)
)

GO

CREATE UNIQUE INDEX UQ_Cozumler_tekil
    ON Cozumler (soruID, cozumTipi)
    WHERE cozumTipi IN (2,4)

GO


CREATE TABLE Yorumlar(
    yorumID         INT IDENTITY(1,1) NOT NULL,
    soruID          INT               NOT NULL,
    kullaniciID     INT               NOT NULL,
    yorumMetni      NVARCHAR(1000)    NOT NULL,
    olusturmaTarihi DATETIME          NOT NULL DEFAULT GETDATE(),
    aktifMi         BIT               NOT NULL DEFAULT 1,

    CONSTRAINT PK_Yorumlar PRIMARY KEY (yorumID),
    CONSTRAINT FK_Yorumlar_Sorular FOREIGN KEY (soruID) REFERENCES Sorular(soruID),
    CONSTRAINT FK_Yorumlar_Kullanicilar FOREIGN KEY (kullaniciID) REFERENCES Kullanicilar(kullaniciID)
)

GO

CREATE INDEX IX_Yorumlar_soru ON Yorumlar (soruID)

GO

CREATE TABLE Begeniler(
    begeniID        INT IDENTITY(1,1) NOT NULL,
    soruID          INT               NOT NULL,
    kullaniciID     INT               NOT NULL,
    olusturmaTarihi DATETIME          NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_Begeniler PRIMARY KEY (begeniID),
    CONSTRAINT FK_Begeniler_Sorular FOREIGN KEY (soruID) REFERENCES Sorular(soruID),
    CONSTRAINT FK_Begeniler_Kullanicilar FOREIGN KEY (kullaniciID) REFERENCES Kullanicilar(kullaniciID),
    CONSTRAINT UQ_Begeniler_soruKullanici UNIQUE (soruID, kullaniciID)
)

GO

CREATE TABLE Bildirimler(
    bildirimID      INT IDENTITY(1,1) NOT NULL,
    kullaniciID     INT               NOT NULL,
    bildirimTipi    NVARCHAR(30)      NOT NULL,
    mesaj           NVARCHAR(500)     NOT NULL,
    hedefURL        NVARCHAR(255)     NULL,
    okunduMu        BIT               NOT NULL DEFAULT 0,
    olusturmaTarihi DATETIME          NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_Bildirimler PRIMARY KEY (bildirimID),
    CONSTRAINT FK_Bildirimler_Kullanicilar FOREIGN KEY (kullaniciID) REFERENCES Kullanicilar(kullaniciID)
)

GO

CREATE INDEX IX_Bildirimler_kullanici ON Bildirimler (kullaniciID, okunduMu)

GO

CREATE TABLE Sikayetler(
    sikayetID       INT IDENTITY(1,1) NOT NULL,
    soruID          INT               NOT NULL,
    kullaniciID     INT               NOT NULL,
    sebep           NVARCHAR(500)     NOT NULL,
    durum           NVARCHAR(20)      NOT NULL DEFAULT N'bekliyor',
    olusturmaTarihi DATETIME          NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_Sikayetler PRIMARY KEY (sikayetID),
    CONSTRAINT FK_Sikayetler_Sorular FOREIGN KEY (soruID) REFERENCES Sorular(soruID),
    CONSTRAINT FK_Sikayetler_Kullanicilar FOREIGN KEY (kullaniciID) REFERENCES Kullanicilar(kullaniciID),
    CONSTRAINT CK_Sikayetler_durum CHECK (durum IN (N'bekliyor', N'incelendi', N'reddedildi'))
)

GO


CREATE TABLE Odevler(
    odevID          INT IDENTITY(1,1) NOT NULL,
    ogretmenID      INT               NOT NULL,
    dersID          INT               NOT NULL,
    baslik          NVARCHAR(150)     NULL,
    baslangicTarihi DATE              NOT NULL,
    bitisTarihi     DATE              NOT NULL,
    durum           NVARCHAR(20)      NOT NULL DEFAULT N'taslak',
    olusturmaTarihi DATETIME          NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_Odevler PRIMARY KEY (odevID),
    CONSTRAINT FK_Odevler_Kullanicilar FOREIGN KEY (ogretmenID) REFERENCES Kullanicilar(kullaniciID),
    CONSTRAINT FK_Odevler_Dersler FOREIGN KEY (dersID) REFERENCES Dersler(dersID),
    CONSTRAINT CK_Odevler_durum CHECK (durum IN (N'taslak', N'yayinda', N'kapandi')),
    CONSTRAINT CK_Odevler_tarih CHECK (bitisTarihi >= baslangicTarihi)
)

GO

CREATE INDEX IX_Odevler_durumTarih ON Odevler (durum, baslangicTarihi, bitisTarihi)

GO

CREATE TABLE OdevSorulari(
    odevSoruID      INT IDENTITY(1,1) NOT NULL,
    odevID          INT               NOT NULL,
    soruID          INT               NOT NULL,
    siraNo          INT               NOT NULL DEFAULT 0,

    CONSTRAINT PK_OdevSorulari PRIMARY KEY (odevSoruID),
    CONSTRAINT FK_OdevSorulari_Odevler FOREIGN KEY (odevID) REFERENCES Odevler(odevID),
    CONSTRAINT FK_OdevSorulari_Sorular FOREIGN KEY (soruID) REFERENCES Sorular(soruID),
    CONSTRAINT UQ_OdevSorulari_odevSoru UNIQUE (odevID, soruID)
)

GO

CREATE TABLE OdevCevaplari(
    odevCevapID     INT IDENTITY(1,1) NOT NULL,
    odevID          INT               NOT NULL,
    soruID          INT               NOT NULL,
    kullaniciID     INT               NOT NULL,
    verilenCevap    NCHAR(1)          NOT NULL,
    dogruMu         BIT               NOT NULL,
    cevapTarihi     DATETIME          NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_OdevCevaplari PRIMARY KEY (odevCevapID),
    CONSTRAINT FK_OdevCevaplari_Odevler FOREIGN KEY (odevID) REFERENCES Odevler(odevID),
    CONSTRAINT FK_OdevCevaplari_Sorular FOREIGN KEY (soruID) REFERENCES Sorular(soruID),
    CONSTRAINT FK_OdevCevaplari_Kullanicilar FOREIGN KEY (kullaniciID) REFERENCES Kullanicilar(kullaniciID),
    CONSTRAINT UQ_OdevCevaplari_tekil UNIQUE (odevID, soruID, kullaniciID),
    CONSTRAINT CK_OdevCevaplari_verilenCevap CHECK (verilenCevap IN (N'A', N'B', N'C', N'D'))
)

GO

CREATE INDEX IX_OdevCevaplari_kullanici ON OdevCevaplari (kullaniciID, odevID)

GO


CREATE TABLE GunlukKonuPlani(
    planID          INT IDENTITY(1,1) NOT NULL,
    planTarihi      DATE              NOT NULL,
    dersID          INT               NOT NULL,
    konuID          INT               NOT NULL,
    kullanildiMi    BIT               NOT NULL DEFAULT 0,

    CONSTRAINT PK_GunlukKonuPlani PRIMARY KEY (planID),
    CONSTRAINT FK_GunlukKonuPlani_Dersler FOREIGN KEY (dersID) REFERENCES Dersler(dersID),
    CONSTRAINT FK_GunlukKonuPlani_Konular FOREIGN KEY (konuID) REFERENCES Konular(konuID),
    CONSTRAINT UQ_GunlukKonuPlani_tarihDers UNIQUE (planTarihi, dersID)
)

GO


CREATE TABLE UretimLog(
    logID           INT IDENTITY(1,1) NOT NULL,
    calismaTarihi   DATE              NOT NULL,
    dersID          INT               NULL,
    konuID          INT               NULL,
    durum           NVARCHAR(20)      NOT NULL,
    hataMesaji      NVARCHAR(MAX)     NULL,
    uretilenSoruID  INT               NULL,
    calismaZamani   DATETIME          NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_UretimLog PRIMARY KEY (logID),
    CONSTRAINT FK_UretimLog_Dersler FOREIGN KEY (dersID) REFERENCES Dersler(dersID),
    CONSTRAINT CK_UretimLog_durum CHECK (durum IN (N'basarili', N'hatali'))
)

GO

CREATE INDEX IX_UretimLog_tarih ON UretimLog (calismaTarihi)

GO

CREATE TABLE Ayarlar(
    ayarID          INT IDENTITY(1,1) NOT NULL,
    ayarAnahtar     NVARCHAR(50)      NOT NULL,
    ayarDeger       NVARCHAR(255)     NOT NULL,

    CONSTRAINT PK_Ayarlar PRIMARY KEY (ayarID),
    CONSTRAINT UQ_Ayarlar_anahtar UNIQUE (ayarAnahtar)
)

GO

CREATE VIEW vw_SoruIstatistik
AS
SELECT
    t.soruID,
    COUNT(*) AS toplamCevap,
    SUM(CASE WHEN t.dogruMu = 0 THEN 1 ELSE 0 END) AS yanlisSayisi,
    CAST(SUM(CASE WHEN t.dogruMu = 0 THEN 1.0 ELSE 0.0 END) * 100 / COUNT(*) AS DECIMAL(5,2)) AS yanlisOrani
FROM(
    SELECT soruID, dogruMu FROM Cevaplar
    UNION ALL
    SELECT soruID, dogruMu FROM OdevCevaplari
) AS t
GROUP BY t.soruID

GO