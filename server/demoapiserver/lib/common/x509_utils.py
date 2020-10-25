from base64 import b64decode

from OpenSSL import crypto


def pem_str_to_x509(pem_str):
    """

    Args:
        pem_str (str): the X509 certificate PEM string

    Returns: (OpenSSL.crypto.X509)

    """
    if not pem_str:
        return None

    try:
        assert isinstance(pem_str, str), type(pem_str)
        pem_lines = [tmp_l.strip() for tmp_l in pem_str.strip().split('\n')]
        assert pem_lines, 'Empty data'
        assert pem_lines[0] == '-----BEGIN CERTIFICATE-----', 'Bad begin'
        assert pem_lines[-1] == '-----END CERTIFICATE-----', 'Bad end'
    except AssertionError as e:
        raise ValueError("`pem_str` is not a valid PEM string. Error: {}".format(e))

    der_data = b64decode("".join(pem_lines[1:-1]))
    return crypto.load_certificate(crypto.FILETYPE_ASN1, der_data)


def get_issuer_cn_from_x509(x509):
    """

    Args:
        x509 (OpenSSL.crypto.X509):

    Returns: (str)

    """
    issuer = x509.get_issuer()
    return issuer.CN


def get_subject_cn_from_x509(x509):
    """

    Args:
        x509 (OpenSSL.crypto.X509):

    Returns: (str)

    """
    subject = x509.get_subject()
    return subject.CN
