class Gdal < Formula
  desc "Geospatial Data Abstraction Library"
  homepage "http://www.gdal.org/"
  url "http://download.osgeo.org/gdal/2.2.3/gdal-2.2.3.tar.gz"
  sha256 "52f01bda8968643633016769607e6082a8ba1c746fadc2c1abe12cf7dc8f61dd"

  depends_on "libpng"
  depends_on "libtiff"
  depends_on "libgeotiff"
  depends_on "geos"
  depends_on "libxml2"
  depends_on "pcre"

  def configure_args
    args = [
      # Base configuration.
      "--prefix=#{prefix}",
      "--mandir=#{man}",
      "--disable-debug",
      "--with-local=#{prefix}",
      "--with-threads",
      "--with-libtool",

      # GDAL native backends.
      "--with-pcraster=internal",
      "--with-pcidsk=internal",
      "--with-bsb",
      "--with-grib",
      "--with-pam",

      # Default Homebrew backends.
      "--with-png=#{Formula["libpng"].opt_prefix}",
      "--with-curl=/usr/bin/curl-config",
      "--with-jpeg=#{HOMEBREW_PREFIX}",
      "--without-jpeg12", # Needs specially configured JPEG and TIFF libraries.
      "--with-gif=#{HOMEBREW_PREFIX}",
      "--with-libtiff=#{HOMEBREW_PREFIX}",
      "--with-geotiff=#{HOMEBREW_PREFIX}",
      "--with-sqlite3=no",
      "--without-freexl",
      "--without-spatialite",
      "--with-geos=#{HOMEBREW_PREFIX}/bin/geos-config",
      "--without-static-proj4",
      "--with-libjson-c=internal",

      # GRASS backend explicitly disabled.  Creates a chicken-and-egg problem.
      # Should be installed separately after GRASS installation using the
      # official GDAL GRASS plugin.
      "--without-grass",
      "--without-libgrass",
      # Disable all scripting language bindings.
      "--without-perl",
      "--without-php",
      "--without-python",
      "--without-ruby",
      # Disable fancy add-on libraries.
      "--without-opencl",
      "--with-armadillo=no"
    ]

    args
  end

  def install
    # Reset ARCHFLAGS to match how we build.
    ENV["ARCHFLAGS"] = "-arch #{MacOS.preferred_arch}"

    # Fix hardcoded mandir: https://trac.osgeo.org/gdal/ticket/5092
    inreplace "configure", %r[^mandir='\$\{prefix\}/man'$], ""

    system "./configure", *configure_args
    system "make"
    system "make", "install"
    system "make", "man" if build.head?
    system "make", "install-man"
    # Clean up any stray doxygen files.
    Dir.glob("#{bin}/*.dox") { |p| rm p }
  end

  def caveats
    if build.with? "mdb"
      <<~EOS
        To have a functional MDB driver, install supporting .jar files in:
          `/Library/Java/Extensions/`

        See: `http://www.gdal.org/ogr/drv_mdb.html`
      EOS
    end
  end

  test do
    # basic tests to see if third-party dylibs are loading OK
    system "#{bin}/gdalinfo", "--formats"
    system "#{bin}/ogrinfo", "--formats"
  end
end
