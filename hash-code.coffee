module.exports = (str) ->
  hash = 0
  return hash if str.length is 0
  i = 0
  while i < str.length
    char = str.charCodeAt(i)
    hash = ((hash << 5) - hash) + char
    hash = hash & hash # Convert to 32bit integer
    i++
  hash
