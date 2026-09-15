defmodule Randonator.ECDSA do
  @moduledoc """
  Small wrapper around Erlang/OTP's `:crypto` ECDSA functions.

  The module uses the `:secp256k1` elliptic curve and SHA-256 digests for
  signing and verification. Keys are returned in the binary format expected by
  `:crypto.sign/4` and `:crypto.verify/5`.
  """

  @curve :secp256k1

  @doc """
  Generates a public/private key pair for the configured ECDSA curve.

  Returns `{public_key, private_key}`.
  """
  def create_keypair(), do: :crypto.generate_key(:ecdh, @curve)

  @doc """
  Signs a message with a private key.

  The message is hashed with SHA-256 before signing. The private key must come
  from `create_keypair/0` or otherwise be compatible with the configured curve.
  """
  def sign(priv, msg) do
    :crypto.sign(:ecdsa, :sha256, msg, [priv, @curve])
  end

  @doc """
  Verifies that a signature was produced for a message by the matching private key.

  Returns `true` for a valid signature and `false` otherwise.
  """
  def verify(pub, msg, sig) do
    :crypto.verify(:ecdsa, :sha256, msg, sig, [pub, @curve])
  end
end
