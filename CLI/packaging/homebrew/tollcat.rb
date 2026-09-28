class Tollcat < Formula
  desc "Your cloud bills, in your pocket"
  homepage "https://tollcat.app"
  version "1.3.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/KUD-00/tollcat/releases/download/v#{version}/tollcat-macos-arm64.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    else
      url "https://github.com/KUD-00/tollcat/releases/download/v#{version}/tollcat-macos-x64.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/KUD-00/tollcat/releases/download/v#{version}/tollcat-linux-aarch64.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    else
      url "https://github.com/KUD-00/tollcat/releases/download/v#{version}/tollcat-linux-x86_64.tar.gz"
      sha256 "0000000000000000000000000000000000000000000000000000000000000000"
    end
  end

  def install
    bin.install "tollcat"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tollcat --version")
  end
end
