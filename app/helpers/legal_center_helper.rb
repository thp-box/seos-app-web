module LegalCenterHelper
  LEGAL_TABS = %w[cgu confidentialite cookies mentions-legales securite].freeze

  def legal_rich_text(body)
    safe_join(body.to_s.split(/\n\n+/).map do |paragraph|
      lines = paragraph.lines.map(&:strip)
      if paragraph.start_with?("## ")
        tag.h3(paragraph.delete_prefix("## "))
      elsif lines.all? { |line| line.start_with?("- ") }
        tag.ul(safe_join(lines.map { |line| tag.li(legal_inline_text(line.delete_prefix("- "))) }))
      elsif lines.size > 2 && lines.all? { |line| line.start_with?("|") } && lines[1].match?(/\A[| :\-]+\z/)
        rows = lines.reject.with_index { |_line, index| index == 1 }.map { |line| line.split("|")[1..].map(&:strip).reject(&:empty?) }
        tag.div(class: "table-scroll", tabindex: 0, role: "region", aria: { label: "Tableau : #{rows.first.join(", ")}" }) do
          tag.table do
            safe_join([ tag.thead(tag.tr(safe_join(rows.shift.map { |cell| tag.th(legal_inline_text(cell), scope: "col") }))), tag.tbody(safe_join(rows.map { |row| tag.tr(safe_join(row.map { |cell| tag.td(legal_inline_text(cell)) })) })) ])
          end
        end
      else
        tag.p(legal_inline_text(paragraph))
      end
    end)
  end

  def legal_inline_text(text)
    safe_join(text.split(/(\*\*[^*]+\*\*|\[[^\]]+\])/).map do |part|
      if part.start_with?("**") && part.end_with?("**")
        tag.strong(part[2...-2])
      elsif part.start_with?("[") && part.end_with?("]")
        tag.mark(part)
      else
        ERB::Util.html_escape(part)
      end
    end)
  end
end
