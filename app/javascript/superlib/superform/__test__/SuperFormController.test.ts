import { SuperFormController } from "../SuperFormController";
import { SuperForm } from "../SuperForm";

interface TestDocShape {
  foo: boolean;
  list: number[];
  obj: { bar: boolean };
}
let controller!: SuperFormController<TestDocShape>;
let onChange!: jest.Mock<any, any>;

beforeEach(() => {
  onChange = jest.fn();
  controller = new SuperFormController<TestDocShape>({ foo: true, list: [1, 2, 3], obj: { bar: false } }, onChange);
});

test("it should allow values to be set at a path", () => {
  controller.setValue("foo", false);
  expect(controller.getValue("foo")).toBe(false);

  controller.setValue("obj.bar", true);
  expect(controller.getValue("obj.bar")).toBe(true);
});

test("it should call the change callback with the new doc when set", () => {
  controller.setValue("foo", false);
  expect(onChange).toMatchSnapshot();
});
