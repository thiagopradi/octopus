After do
  `rm #{Rails.root.to_s}/db/america.sqlite3`
  `rm #{Rails.root.to_s}/db/asia.sqlite3`
  `rm #{Rails.root.to_s}/db/development.sqlite3`
  `rm #{Rails.root.to_s}/db/europe.sqlite3`
end

Before do
  `rm #{Rails.root.to_s}/db/america.sqlite3`
  `rm #{Rails.root.to_s}/db/asia.sqlite3`
  `rm #{Rails.root.to_s}/db/development.sqlite3`
  `rm #{Rails.root.to_s}/db/europe.sqlite3`
end
