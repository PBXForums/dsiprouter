import sys

sys.path.insert(0, '/etc/dsiprouter/gui')

import requests, functools, secrets, datetime
from util.security import Credentials, AES_CTR

class WoocommerceError(requests.HTTPError):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

def wcApiPropagateHttpError(method):
    @functools.wraps(method)
    def wrapper(self, *args, **kwargs):
        try:
            return method(self, *args, **kwargs)
        except requests.HTTPError as ex:
            ex.response._content = ex.response.content.replace(self._license_key.encode('utf-8'), b'<redacted>')
            raise WoocommerceError(response=ex.response)
    return wrapper

class WoocommerceLicense(object):
    # this API key is locked down to only allow functionality below
    SERVER = {
        "baseurl": "https://dopensource.com/wp-json/lmfwc/v2/licenses/",
        "key": "ck_068f510a518ff5ecf1cbdcbc7db7f9bac2331613",
        "secret": "cs_5ae2f3decfa59f427a59b41f2e41459d18023dd7",
    }
    # woocommerce product ID -> dsiprouter license type
    TYPE = {
        2583: 'DSIP_CORE_LICENSE',
        3741: 'DSIP_STIRSHAKEN_LICENSE',
        3675: 'DSIP_TRANSNEXUS_LICENSE',
        2769: 'DSIP_MSTEAMS_LICENSE',
        2570: 'DSIP_MSTEAMS_LICENSE',
        2569: 'DSIP_MSTEAMS_LICENSE',
        2556: 'DSIP_MSTEAMS_LICENSE',
    }
    # constant salt used for equality checks
    # should not be used for generating a hash that is stored
    CMP_SALT = 'A' * Credentials.SALT_LEN
    # the woocommerce license length may change due to application specific requirements
    # therefore we parse it out based on the length of the machine id, which will not change
    MACHINE_ID_LEN = 32

    def __init__(self, license_key=None, key_combo=None, decrypt=False):
        if license_key is not None:
            if key_combo is not None:
                raise ValueError('license_key and key_combo are mutually exclusive')

            if isinstance(license_key, str):
                if len(license_key) == 0:
                    raise ValueError('license_key must not be empty')
                if decrypt:
                    license_key = AES_CTR.decrypt(license_key).decode('utf-8')
            elif isinstance(license_key, bytes):
                if len(license_key) == 0:
                    raise ValueError('license_key must not be empty')
                if decrypt:
                    license_key = AES_CTR.decrypt(license_key).decode('utf-8')
                else:
                    license_key = license_key.decode('utf-8')
            else:
                raise ValueError('license_key must be a string or byte string')

            with open('/etc/machine-id', 'r') as f:
                machine_id = f.read().rstrip()
                if len(machine_id) != WoocommerceLicense.MACHINE_ID_LEN:
                    raise Exception("machine_id must be {} characters long".format(WoocommerceLicense.MACHINE_ID_LEN))
        elif key_combo is not None:
            if isinstance(key_combo, str):
                if len(key_combo) == 0:
                    raise ValueError('key_combo must not be empty')
            elif isinstance(key_combo, bytes):
                if len(key_combo) == 0:
                    raise ValueError('key_combo must not be empty')
                if decrypt:
                    key_combo = AES_CTR.decrypt(key_combo).decode('utf-8')
                else:
                    key_combo = key_combo.decode('utf-8')
            else:
                raise ValueError('key_combo must be a string or byte string')

            try:
                license_key = key_combo[:-WoocommerceLicense.MACHINE_ID_LEN]
                machine_id = key_combo[-WoocommerceLicense.MACHINE_ID_LEN:]
            except IndexError:
                raise ValueError('key_combo is invalid')
        else:
            raise ValueError('one of license_key or key_combo is required')

        # set attributes based on clientside data
        self._license_key = license_key
        self.__machine_id = machine_id

        # set attributes based on serverside data
        self.sync()

    # def __hash__(self):
    #     return hash(self.hash(WoocommerceLicense.CMP_SALT))

    def __eq__(self, obj):
        return isinstance(obj, WoocommerceLicense) and secrets.compare_digest(self.hash(WoocommerceLicense.CMP_SALT), obj.hash(WoocommerceLicense.CMP_SALT))

    def __ne__(self, obj):
        return not self.__eq__(obj)

    # allow passing to dict() and iterable()
    def __iter__(self):
        for k,v in self.asDict().items():
            yield k,v

    # only return select attributes in the iterable/dict representation
    def asDict(self):
        return {
            'type': self.type,
            'expires': self.expires,
            'active': self.active,
            'license_key': self.license_key,
        }

    @property
    def type(self):
        return self._type

    @property
    def expires(self):
        if self._expires_at is not None:
            return datetime.datetime.strptime(self._expires_at, '%Y-%m-%d %H:%M:%S')
        return datetime.datetime.strptime(self._created_at, '%Y-%m-%d %H:%M:%S') + datetime.timedelta(days=self._valid_for)

    @property
    def active(self):
        return self._status == 3 and self._times_activated > 0 and self.expires > datetime.datetime.now()

    @property
    def license_key(self):
        return self._license_key

    # noinspection PyArgumentList
    @wcApiPropagateHttpError
    def sync(self):
        r = requests.get(
            WoocommerceLicense.SERVER['baseurl'] + self._license_key,
            auth=(
                WoocommerceLicense.SERVER['key'],
                WoocommerceLicense.SERVER['secret']
            )
        )
        r.raise_for_status()
        data = r.json()['data']

        # make sure woocommerce product associates to a license type
        try:
            self._type = WoocommerceLicense.TYPE[data["productId"]]
        except KeyError:
            raise ValueError("license type for product id <{}> not found".format(str(data["productId"])))

        # self._id = data["id"]
        # self._order_id = data["orderId"]
        # self._user_id = data["userId"]
        self._expires_at = data["expiresAt"]
        self._valid_for = data["validFor"]
        # self._source = data["source"]
        self._status = data["status"]
        self._times_activated = data["timesActivated"]
        self._times_activated_max = data["timesActivatedMax"]
        self._created_at = data["createdAt"]
        # self._created_by = data["createdBy"]
        self._updated_at = data["updatedAt"]
        # self._updated_by = data["updatedBy"]

    @wcApiPropagateHttpError
    def activate(self):
        r = requests.get(
            WoocommerceLicense.SERVER['baseurl'] + 'activate/' + self._license_key,
            auth=(
                WoocommerceLicense.SERVER['key'],
                WoocommerceLicense.SERVER['secret']
            )
        )
        r.raise_for_status()
        r_json = r.json()

        self._times_activated = r_json['data']['timesActivated']
        self._times_activated_max = r_json['data']['timesActivatedMax']
        self._updated_at = r_json['data']['updatedAt']

        return r_json.get('success', False)

    @wcApiPropagateHttpError
    def deactivate(self):
        r = requests.get(
            WoocommerceLicense.SERVER['baseurl'] + 'deactivate/' + self._license_key,
            auth=(
                WoocommerceLicense.SERVER['key'],
                WoocommerceLicense.SERVER['secret']
            )
        )
        r.raise_for_status()
        r_json = r.json()

        self._times_activated = r_json['data']['timesActivated']
        self._times_activated_max = r_json['data']['timesActivatedMax']
        self._updated_at = r_json['data']['updatedAt']

        return r_json.get('success', False)

    def hash(self, salt=None):
        return Credentials.hashCreds('{}{}'.format(self._license_key, self.__machine_id), salt)

    # need original key for queries to woocommerce
    # format: license_key-machine_id
    def encrypt(self):
        return AES_CTR.encrypt('{}{}'.format(self._license_key, self.__machine_id))
