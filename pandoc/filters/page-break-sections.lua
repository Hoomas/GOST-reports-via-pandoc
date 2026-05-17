-- Вставляет \clearpage перед каждым заголовком первого уровня (h1).
-- Это нужно потому что titlesec/\sectionbreak делает clearpage ПОСЛЕ якоря секции,
-- из-за чего hyperref-цель оказывается на предыдущей странице, и ссылки из TOC ведут
-- на страницу раньше. Решение — переносить страницу ДО заголовка, чтобы и якорь,
-- и заголовок были на одной (новой) странице.

local first_header_seen = false

function Header(el)
  if el.level ~= 1 then return nil end
  if not first_header_seen then
    -- Первый h1 не переносим — он идёт сразу после TOC, у которого уже есть свой \clearpage.
    first_header_seen = true
    return nil
  end
  return {
    pandoc.RawBlock("latex", "\\clearpage\\phantomsection"),
    el
  }
end
