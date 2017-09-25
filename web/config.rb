###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

# With alternative layout
# page "/path/to/file.html", layout: :otherlayout

# Proxy pages (http://middlemanapp.com/basics/dynamic-pages/)
# proxy "/this-page-has-no-template.html", "/template-file.html", locals: {
#  which_fake_page: "Rendering a fake page with a local variable" }
yearly_playlists = {
  2015 => "spotify:user:westiecharts:playlist:1bp4iizhemNjuHMRtiAQdC",
  2016 => "spotify:user:westiecharts:playlist:2pDOKcm0XTRVY3iKQa3Q4S",
  2017 => "spotify:user:westiecharts:playlist:20Z54LAupPDy26uL3axS4i"
}
yearly_playlists.each do |year, playlist_id|
  proxy "/#{year}.html", "year.html", locals: { year: year, playlist_id: playlist_id }
end

# General configuration

# Reload the browser automatically whenever files change
configure :development do
  activate :livereload
end

###
# Helpers
###

# Methods defined in the helpers block are available in templates
# helpers do
#   def some_helper
#     "Helping"
#   end
# end

# Build-specific configuration
configure :build do
  # Minify CSS on build
  # activate :minify_css

  # Minify Javascript on build
  # activate :minify_javascript
end
