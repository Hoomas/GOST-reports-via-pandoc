# AGENT TO READ — карта быстрых правок

Файл для AI/агента: куда лезть и чего опасаться, чтобы внести правку за один заход без сборки-перебора.

---

## 0. Цикл работы

1. Прочитать этот файл + `README.md`.
2. Внести правку (см. таблицу ниже).
3. Пересобрать тест:
   ```powershell
   C:\Reports__pandoc_template\pandoc\build.ps1 C:\Reports__pandoc_template\works\test\test-all-features.md -Open
   ```
4. Если пользователь правит «по живому» отчёт — собирать его, а не test-all-features.

---

## 1. Карта файлов

| Файл                                                | Что внутри                                                                |
| --------------------------------------------------- | ------------------------------------------------------------------------- |
| `pandoc/template.tex`                               | LaTeX-шаблон. Всё оформление страницы, заголовков, TOC, кода, титульника. |
| `pandoc/gost_report.yaml`                           | Pandoc defaults: фильтры, шрифты, поля, метаданные (префиксы crossref).   |
| `pandoc/filters/gost-tables.lua`                    | Рендер таблиц через `xltabular`.                                          |
| `pandoc/filters/page-break-sections.lua`            | Вставка `\clearpage\phantomsection` перед каждым h1 (кроме первого).      |
| `pandoc/bibliography/sources.bib`                   | Источники (BibTeX).                                                       |
| `pandoc/bibliography/gost-r-7-0-5-2008-numeric.csl` | CSL-стиль ГОСТ.                                                           |
| `pandoc/logo.png`                                   | Логотип ТПУ для титульника.                                               |
| `pandoc/build.ps1`                                  | Скрипт сборки (`-Open` чтобы открыть PDF).                                |
| `works/test/test-all-features.md`                   | Эталон со всеми фичами — для быстрой проверки регрессий.                  |

---

## 2. «Хочу изменить X» → куда лезть

| Что менять                                        | Файл                          | Где конкретно                                                                                |
| ------------------------------------------------- | ----------------------------- | -------------------------------------------------------------------------------------------- |
| Шапку титульника (вуз, школа, лого)               | `template.tex`                | блок `\begin{titlepage} ... \end{titlepage}` после `\begin{document}`                        |
| Дефолтного автора / группу                        | `template.tex`                | `$else$`-ветки внутри titlepage (`Макаров С. А.`, `8Е31`)                                    |
| Размер логотипа                                   | `template.tex`                | `\includegraphics[height=3.2cm]{...logo.png}` в titlepage                                    |
| Шрифт основной/sans/mono                          | `template.tex`                | секция 2: `\setmainfont`, `\setsansfont`, `\setmonofont`                                     |
| Поля страницы                                     | `template.tex`                | секция 3: `\usepackage[left=30mm,right=15mm,top=20mm,bottom=20mm]{geometry}`                 |
| Межстрочный интервал                              | `template.tex`                | секция 4: `\onehalfspacing` (заменить на `\singlespacing`/`\doublespacing`)                  |
| Абзацный отступ                                   | `template.tex`                | секция 4: `\setlength{\parindent}{1.25cm}`                                                   |
| Формат h1 (section)                               | `template.tex`                | секция 5: `\titleformat{\section}{...}`                                                      |
| Формат h2/h3                                      | `template.tex`                | `\titleformat{\subsection}` / `\titleformat{\subsubsection}`                                 |
| TOC: лидеры/отступы/межстрочный интервал          | `template.tex`                | секция 5, подразделы 6–9 (`\cftsecleader`, `\cft*indent`, `\cftbefore*skip`)                 |
| Префиксы crossref («табл.», «рис.», «разд.»)      | `gost_report.yaml`            | блок `metadata`: `tblPrefix`, `figPrefix`, `eqnPrefix`, `secPrefix`                          |
| Подписи «Рисунок»/«Таблица»                       | `template.tex`                | секция 7: `\renewcommand{\figurename}`, `\renewcommand{\tablename}` + `gost_report.yaml`     |
| Рамка/нумерация кода                              | `template.tex`                | секция 1: `\RecustomVerbatimEnvironment{Highlighting}` + секция 13: `Shaded`/`framed`        |
| Стиль библиографии (ГОСТ → другой)                | `pandoc/bibliography/*.csl`   | заменить файл или путь в `gost_report.yaml` (`csl:`)                                         |
| Рендеринг таблиц (колонки, разрывы, линии)        | `filters/gost-tables.lua`     | весь файл — там одна функция, читается за минуту                                              |
| Поведение разрыва страниц перед h1                | `filters/page-break-sections.lua` | один тривиальный Header-handler                                                          |

---

## 3. Хрупкие места — НЕ ТРОГАТЬ без понимания

### 3.1. `\sectionbreak` пустой
В `template.tex` секция 5: `\newcommand{\sectionbreak}{}`.
**Не возвращай туда `\clearpage`** — сломаются hyperref-ссылки из TOC для `{.unnumbered}` секций («Выводы», «Список литературы»). Разрыв страниц + якорь делает Lua-фильтр `page-break-sections.lua` через `\clearpage\phantomsection` ПЕРЕД заголовком.

### 3.2. Порядок команд в `\tabularxcolumn`
В `template.tex` секция 6:
```latex
\renewcommand\tabularxcolumn[1]{>{\justifying\arraybackslash\hyphenpenalty=0\exhyphenpenalty=0\setlength{\parindent}{0pt}\everypar{}\hspace{0pt}}p{#1}}
```
`\justifying\arraybackslash` ОБЯЗАТЕЛЬНО ПЕРВЫМ. Если поставить после `\setlength{\parindent}{0pt}` — ragged2e перебивает сброс и первая строка в ячейке получает абзацный отступ 1.25см.

### 3.3. `\RecustomVerbatimEnvironment`, не `\RecustomizeVerbatimEnvironment`
В `template.tex` секция 1. fvextra использует короткую форму. Если написать длинную — сборка падает на любом блоке кода с подсветкой.

### 3.4. `secPrefix` обязателен
В `gost_report.yaml/metadata`. Без него `@sec:label` рендерится как «sec. N» вместо «разд. N».

### 3.5. Список литературы требует div
В .md:
```markdown
# Список литературы {.unnumbered}

::: {#refs}
:::
```
Без `::: {#refs} :::` библиография уйдёт в самый конец документа (после приложений) — это плохо по ГОСТу.

### 3.6. Двойной `\hline` в таблицах
В `gost-tables.lua`: перед `\endlastfoot` НЕ ставить `\hline` — последняя строка тела уже ставит свой. Если поставить — получишь двойную жирную нижнюю линию.

### 3.7. Каждое приложение через `\app{Буква}{Название}`
Команда определена в `template.tex` секция 14. Сама вставляет `\clearpage` + центрирует заголовок. Не пиши `\section*{Приложение А}` руками — будет дубль.

---

## 4. Команды для самопроверки

```powershell
# Полная пересборка теста с открытием PDF
C:\Reports__pandoc_template\pandoc\build.ps1 C:\Reports__pandoc_template\works\test\test-all-features.md -Open

# Сгенерировать промежуточный .tex для дебага анкеров/структуры
cd C:\Reports__pandoc_template\works\test
pandoc --to=latex `
  --template=C:/Reports__pandoc_template/pandoc/template.tex `
  --filter pandoc-crossref `
  --lua-filter=C:/Reports__pandoc_template/pandoc/filters/page-break-sections.lua `
  --lua-filter=C:/Reports__pandoc_template/pandoc/filters/gost-tables.lua `
  --citeproc `
  --bibliography=C:/Reports__pandoc_template/pandoc/bibliography/sources.bib `
  --csl=C:/Reports__pandoc_template/pandoc/bibliography/gost-r-7-0-5-2008-numeric.csl `
  -o test-debug.tex test-all-features.md
```

---

## 5. Чек-лист регрессий после правки

После любой правки в `template.tex` / фильтрах прогнать `test-all-features.md` и глазами проверить PDF:

- [ ] Титульник: лого по центру, шапка министерства/ТПУ, тип работы, авторы, преподаватель, «Томск 2026».
- [ ] Стр. 2: оглавление — все уровни выровнены по левому краю, точки-лидеры до номеров, равные межстрочные интервалы.
- [ ] Клик по «Выводы» и «Список литературы» в TOC → попадает на нужную страницу.
- [ ] Каждый `#`-заголовок на новой странице, по центру, нумерованный (кроме `{.unnumbered}`).
- [ ] Таблицы: рамка по всем сторонам, без двойной нижней линии, абзацный отступ первой строки в ячейках = 0.
- [ ] Блок кода: рамка, нумерация строк 14pt (не мелкая), перенос длинных строк.
- [ ] Формулы: нумерация справа, ссылки `\eqref{}` работают.
- [ ] Цитата `[@test2024]` → `[1]`, список литературы перед приложениями.
- [ ] Приложение А и Б — каждое с новой страницы, «Приложение А» жирным по центру + название.

---

## 6. YAML, дефолты, что зашито в шаблон

См. `pandoc/AI_WRITING_GUIDE.md` секцию 2.1 и 5 — там полный список полей YAML и дефолтов (автор «Макаров С. А.», группа «8Е31», город Томск, год = текущий).
