-- ИСПРАВЛЕННЫЙ addlines.lua (Версия с поддержкой Label и Stringify)

local utils = require 'pandoc.utils'
local stringify = utils.stringify  -- ВОТ ЭТОЙ СТРОКИ НЕ ХВАТАЛО

-- Функция рендеринга одной строки
local function row_tex(row, num_cols)
  local parts = {}
  
  for i = 1, num_cols do
    if i > 1 then table.insert(parts, " & ") end
    
    local cell = row.cells[i]
    if cell then
       local content_tex = pandoc.write(pandoc.Pandoc(cell.contents), 'latex')
       content_tex = content_tex:gsub("\n", " ")
       table.insert(parts, content_tex)
    else
       table.insert(parts, "")
    end
  end

  table.insert(parts, " \\\\ \\hline\n")
  return table.concat(parts)
end

function Table(el)
  -- 1. Определяем количество колонок
  local num_columns = 0
  if el.colspecs then num_columns = #el.colspecs end
  if num_columns == 0 and el.head and el.head.rows and #el.head.rows > 0 then
     num_columns = #el.head.rows[1].cells
  end
  if num_columns == 0 then return el end 

  -- 2. Преамбула
  local spec = "|"
  for _ = 1, num_columns do spec = spec .. "X|" end

  local tex = {}
  table.insert(tex, "\\begin{xltabular}{\\linewidth}{" .. spec .. "}\n")
  
  -- 3. Подпись и МЕТКА (LABEL)
  if el.caption and (el.caption.long or el.caption.short) then
     local caption_text = stringify(el.caption.long or el.caption.short)
     if caption_text ~= "" then
        local label_tex = ""
        -- Сохраняем ID таблицы для ссылок (crossref)
        if el.identifier and el.identifier ~= "" then
           label_tex = "\\label{" .. el.identifier .. "}"
        end
        table.insert(tex, "\\caption{" .. caption_text .. "} " .. label_tex .. " \\\\\n")
     end
  end

  -- 4. Заголовок таблицы
  if el.head and el.head.rows then
    -- firsthead: рисуется на ПЕРВОЙ странице таблицы
    table.insert(tex, "\\hline\n")
    for _, row in ipairs(el.head.rows) do
       table.insert(tex, row_tex(row, num_columns))
    end
    table.insert(tex, "\\endfirsthead\n")

    -- head: рисуется в начале КАЖДОЙ последующей страницы при разрыве
    table.insert(tex, "\\hline\n")
    for _, row in ipairs(el.head.rows) do
       table.insert(tex, row_tex(row, num_columns))
    end
    table.insert(tex, "\\endhead\n")
  end

  -- 4.5. Подвал при разрыве страницы (foot) и финальный подвал (lastfoot)
  -- НЕ добавляем \hline ни в endfoot, ни в endlastfoot: последняя видимая строка
  -- тела (как при разрыве, так и в конце таблицы) уже ставит свой \hline через
  -- row_tex. Если добавить ещё один — получим двойную жирную линию снизу
  -- (заметно особенно при разрыве таблицы на 2 листа: нижний край верхней
  -- части становится двойным).
  table.insert(tex, "\\endfoot\n")
  table.insert(tex, "\\endlastfoot\n")

  -- 5. Тело
  if el.bodies then
    for _, body in ipairs(el.bodies) do
      local rows_list = body.rows or body.body or {} 
      for _, row in ipairs(rows_list) do
        table.insert(tex, row_tex(row, num_columns))
      end
    end
  end
  
  -- 6. Подвал
  if el.foot and el.foot.rows then
     for _, row in ipairs(el.foot.rows) do
        table.insert(tex, row_tex(row, num_columns))
     end
  end

  table.insert(tex, "\\end{xltabular}")

  return pandoc.RawBlock("latex", table.concat(tex))
end
