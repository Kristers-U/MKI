## Drošības brīdinājums

**Svarīgi:** šī projekta pašreizējā versija izmanto novecojušu Electron versiju, kurai ir konstatētas drošības ievainojamības.

Saskaņā ar `npm audit` pārbaudi projektā ir konstatētas 2 augstas nopietnības (high severity) ievainojamības, kas saistītas ar `extract-zip` pakotni. Šī pakotne tiek izmantota kā Electron atkarība.

Konkrētā ievainojamība ir saistīta ar nepietiekamu simbolisko saišu (symlink) ceļu pārbaudi, kas noteiktos apstākļos var radīt **path traversal** risku.

Šobrīd `npm audit` piedāvā problēmu novērst ar: `npm audit fix --force`

Tomēr šī komanda veic arī **būtisku Electron versijas atjaunināšanu**, kas var izraisīt nesaderības ar pašreizējo projekta kodu.

Ieteikums: pirms programmas izmantošanas vispirms atjaunināt Electron uz atbalstītu un drošu versiju un pārbaudīt projekta saderību ar jauno versiju.

## Par programmu

Šī programma bija prakses uzdevums. Tās mērķis ir aprēķināt metāla konstruckiju izturību, attēlot Eilera kritiskā spēka grafiku, vizualizēt kolonnu. Tā ir izstrādāta kā darbvirsmas lietotne operētājsistēmai Windows, izmantojot Vue.js, Vite, Three.js un Electron.





## Darba sākšana

### Priekšnosacījumi

* [Node.js](https://nodejs.org/) 18. versija vai jaunāka
* npm

### Instalēšana

Klonējiet repozitoriju un instalējiet nepieciešamās atkarības:

```bash
git clone https://github.com/Kristers-U/MKI
cd mki
npm install
```

### Izstrāde

Lai palaistu lietotni izstrādes režīmā:

```bash
npm run dev
```

Tiek palaists Vite izstrādes serveris un atvērta Electron darbvirsmas lietotne.

### Būvēšana

Lai izveidotu Vue priekšgala (frontend) versiju:

```bash
npm run build
```

Gatavā priekšgala versija tiek izveidota `dist` direktorijā.

### Darbvirsmas instalēšanas programmas izveide

Lai izveidotu pilnu Electron darbvirsmas lietotni un instalēšanas programmu:

```bash
npm run dist
```

Electron Builder izveido lietotni operētājsistēmai Windows, izmantojot NSIS.

Izveidotā instalēšanas programma atradīsies `dist` direktorijā.

Windows instalēšanas programmu var palaist, atverot izveidoto `.exe` failu.

### Lietotnes palaišana

Lai palaistu Electron tieši no projekta:

```bash
npm start
```

### Pieejamās komandas

| Komanda         | Apraksts                              |
| --------------- | ------------------------------------- |
| `npm install`   | Instalē projekta atkarības            |
| `npm run dev`   | Palaiž lietotni izstrādes režīmā      |
| `npm run build` | Izveido Vue priekšgala versiju        |
| `npm run dist`  | Izveido Electron darbvirsmas lietotni |
| `npm start`     | Palaiž Electron lietotni              |

### Instalēšana operētājsistēmā Windows

Pēc komandas izpildes:

```bash
npm run dist
```

atveriet izveidoto `.exe` instalēšanas programmu no `dist` direktorijas un izpildiet instalēšanas norādījumus.

Instalēšanas programma ļauj izvēlēties instalēšanas direktoriju.
