import http from 'k6/http';
import { sleep, check } from 'k6';

const BASE_URL = __ENV.BASE_URL

export const options = {
  vus: 60,
  duration: '5s',
};

export default function() {
  let res = http.get(BASE_URL);
  check(res, { "status is 200": (res) => res.status === 200 });
  sleep(1);
}
