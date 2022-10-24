{ #try
  echo "Attempting to serve ${pwd} using 'SimpleHttpServer'..."
  python -m SimpleHttpServer $1
} || { #catch
  echo "FAILED to serve ${pwd} using 'SimpleHttpServer'..."
  echo "Attempting to serve ${pwd} using 'http.server'..."
  python -m http.server $1
}