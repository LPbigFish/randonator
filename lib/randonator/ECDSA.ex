defmodule Randonator.ECDSA do
  @curve :secp256k1

  def create_keypair(), do: :crypto.generate_key(:ecdh, @curve)

  def sign(priv, msg) do
    :crypto.sign(:ecdsa, :sha256, msg, [priv, @curve])
  end

  def verify(pub, msg, sig) do
    :crypto.verify(:ecdsa, :sha256, msg, sig, [pub, @curve])
  end
end
