# Pandoc-шаблон отчётов ТПУ (ГОСТ)

Шаблон для генерации академических отчётов (лабораторные, курсовые, РГР) в PDF из Markdown через Pandoc + XeLaTeX. Соответствует ГОСТ 2.105-95 и требованиям к оформлению ТПУ (ИШИТР).

## Структура проекта

```
C:\Reports__pandoc_template\
├── pandoc\                      # Конфигурация и шаблон
│   ├── build.ps1                # Скрипт сборки PDF из .md
│   ├── gost_report.yaml         # Pandoc defaults (фильтры, шрифты, поля)
│   ├── template.tex             # LaTeX-шаблон документа
│   ├── logo.png                 # Логотип ТПУ для титульника
│   ├── AI_WRITING_GUIDE.md      # Инструкция для AI: как писать .md под шаблон
│   ├── bibliography\            # .bib-файлы и CSL-стиль (ГОСТ Р 7.0.5-2008)
│   └── filters\
│       ├── gost-tables.lua      # Lua-фильтр: рендер таблиц через xltabular
│       └── page-break-sections.lua  # Lua-фильтр: \clearpage + \phantomsection перед h1
├── works\                       # Папка с конкретными отчётами
│   └── test\
│       └── test-all-features.md # Тестовый .md, использует все возможности шаблона
├── setup-symlinks.ps1           # Скрипт для линковки в Zettlr/др.
└── README.md
```

## Быстрый старт

```powershell
C:\Reports__pandoc_template\pandoc\build.ps1 .\works\test\test-all-features.md
```

PDF сгенерируется рядом с `.md`. Флаг `-Open` сразу откроет результат.

## Что поддерживается

- **Титульный лист ТПУ** — генерируется автоматически из YAML-метаданных (тип работы, дисциплина, тема, ФИО автора(ов), преподавателя). Логотип ТПУ + шапка министерства зашиты в `template.tex`.
- **Содержание** — все уровни выровнены по левому краю, точки-лидеры, равные межстрочные интервалы. Кликабельные ссылки ведут точно на нужную страницу (включая `{.unnumbered}` секции).
- **Заголовки** — h1 центрируется и начинается с новой страницы, h2-h4 с абзацного отступа 1.25см.
- **Таблицы** — `xltabular`, равные колонки, повтор шапки на разрывах страниц, перенос длинных слов в ячейках, абзацный отступ первой строки внутри ячейки.
- **Формулы** — `amsmath`/`mathtools`, нумерованные через `\begin{equation}...\end{equation}`, системы через `cases` с расширенным интервалом.
- **Код** — рамка, нумерация строк, Times New Roman 14pt, перенос длинных строк.
- **Цитаты** — `[@key]` через citeproc + CSL (ГОСТ Р 7.0.5-2008 numeric).
- **Перекрёстные ссылки** — pandoc-crossref: `@tbl:`, `@fig:`, `@eq:`, `@sec:` → «табл. N», «рис. N», «ф. N», «разд. N».
- **Список литературы** — размещается через div `::: {#refs} :::`, может стоять до приложений.
- **Приложения** — команда `\app{А}{Название}` начинает новую страницу с центрированным заголовком «Приложение А» + название.

## Требования

- **MiKTeX / TeX Live** с XeLaTeX и пакетами: `extarticle`, `fontspec`, `babel-russian`, `xltabular`, `tocloft`, `titlesec`, `enumitem`, `framed`, `fancyvrb`, `fvextra`, `unicode-math`, `hyperref`, `bookmark`.
- **Pandoc ≥ 3.0** с фильтрами `pandoc-crossref` и `citeproc`.
- **Шрифты**: Times New Roman, Arial, Courier New, XITS Math.
- **PowerShell 5+** для `build.ps1`.

## Как писать .md под шаблон

Полное руководство — [`pandoc/AI_WRITING_GUIDE.md`](pandoc/AI_WRITING_GUIDE.md). Минимальный пример:

```markdown
---
doc-type: "Лабораторная работа"
work-number: "3"
subject: "Теоретическая механика"
title: "Исследование колебаний"
teacher-position: "доцент, к.т.н."
teacher: "Иванов И. И."
author: "Макаров С. А."
group: "8Е31"
date: "2026"
lang: ru
toc: true
number-sections: true
---

# Цель работы {.unnumbered}

Текст цели.

# Теоретическая часть

Текст с формулой $E = mc^2$ и ссылкой на источник [@key2024].

# Выводы {.unnumbered}

Краткие выводы.

# Список литературы {.unnumbered}

::: {#refs}
:::
```

## Полный пример

`works/test/test-all-features.md` использует **все** возможности шаблона: титульник с несколькими авторами, формулы, системы уравнений, таблицы с crossref, код, цитаты, список литературы и приложения. Хорошая отправная точка для нового отчёта.

## Где менять что

| Хочу изменить                       | Где                                                              |
| ----------------------------------- | ---------------------------------------------------------------- |
| Шапку титульника (вуз, школа)       | `pandoc/template.tex`, блок `\begin{titlepage}`                  |
| Дефолтного автора / группу          | `pandoc/template.tex`, блок `\begin{titlepage}` (`$else$` ветки) |
| Шрифт / размер                      | `pandoc/template.tex`, секция 2 / 4                              |
| Поля страницы                       | `pandoc/template.tex`, секция 3 (`\usepackage[...]{geometry}`)   |
| Формат заголовков                   | `pandoc/template.tex`, секция 5 (`\titleformat{...}`)            |
| Формат TOC (отступы, лидеры)        | `pandoc/template.tex`, секция 5, подразделы 6–9                  |
| Префиксы crossref («табл.», «рис.») | `pandoc/gost_report.yaml`, блок `metadata`                       |
| Стиль библиографии                  | `pandoc/bibliography/*.csl`                                      |
