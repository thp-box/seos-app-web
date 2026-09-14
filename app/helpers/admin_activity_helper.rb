module AdminActivityHelper
  def activity_chart_max(activity)
    maximum = activity.series.flat_map { |row| [ row[:registrations], row[:publications] ] }.max
    [ maximum, 2 ].max
  end

  def activity_chart_path(activity, key)
    maximum = activity_chart_max(activity)
    activity.series.each_with_index.map do |row, index|
      x = 48 + index * 696.0 / (activity.days - 1)
      y = 220 - row.fetch(key) * 180.0 / maximum
      "#{index.zero? ? 'M' : 'L'} #{x.round(2)} #{y.round(2)}"
    end.join(" ")
  end

  def activity_comparison(current, previous)
    return previous.zero? ? "Aucun événement sur les deux périodes" : "−100 % par rapport à la période précédente" if current.zero?
    return "+#{current} · aucun événement sur la période précédente" if previous.zero?
    difference = ((current - previous) * 100.0 / previous).round
    "#{difference.positive? ? '+' : ''}#{difference} % par rapport à la période précédente"
  end
end
