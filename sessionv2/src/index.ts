import { ResponseBuilder } from "@fermyon/spin-sdk";
import { factory } from 'ulid'

export async function handler(req: Request, res: ResponseBuilder) {
  const prng = () => Math.random(); // allow insecure ulids
  const ulid = factory(prng);


  const flavours = ["chicken", "fish", "beef", "veg"];
  const max_index = 30000;

  let randomFlavour = (): string => {
    return flavours[Math.floor(Math.random()*flavours.length)];
  }

  var index = 0;
  var menu = [];
  while (index < max_index) {
    menu.push({ demand: randomFlavour(), offset: index });
    index += randomIntInRange(1000, 3000);
  }

  res.send(JSON.stringify({
    id: ulid(),
    menu: menu
  }));
}

function randomIntInRange(min: number, max: number) : number {
  return Math.floor(Math.random() * (max - min + 1) + min);
}
