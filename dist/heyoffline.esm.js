const Heyoffline = class Heyoffline {

  constructor(options){

    // default options
    this.options = {
      text: {
        offline: {
          heading: "You're currently offline",
          desc:    "Wait until your network comes back before continuing.",
          button:  "Dismiss",
          icon:    `<svg height="24" version="1.1" viewBox="0 0 24 24"><g stroke-linecap="round" stroke-width="2" fill="none" stroke-linejoin="round"><line x1="1" x2="23" y1="1" y2="23"></line><path d="M16.72 11.06l1.5538e-07 7.58308e-08c.819101.399751 1.58504.900296 2.28 1.49"></path><path d="M5 12.55l-8.62439e-07 7.21087e-07c1.48208-1.23917 3.26587-2.06379 5.17-2.39"></path><path d="M10.71 5.05l3.44455e-07-2.77554e-08c4.32877-.348802 8.61336 1.07699 11.87 3.95"></path><path d="M1.42 9l-4.4094e-07 3.89757e-07c1.38716-1.22615 2.9777-2.20077 4.7-2.88"></path><path d="M8.53 16.11l4.96807e-07-3.52957e-07c2.08083-1.47833 4.86917-1.47833 6.95 7.05914e-07"></path><line x1="12" x2="12.01" y1="20" y2="20"></line></g></svg>`
        },
        online: {}
      },
      monitorFields:  false,
      prefix:         "heyoffline",
      noStyles:       false,
      disableDismiss: false,
      overlay:        true,
      fields:         "input, select, textarea, *[contenteditable]"
      // onOnline:  () => {},
      // onOffline: () => {}
    };

    // set a global flag if any field on the page has been modified
    this.modified = false;

    this.defaultStyles = `
      .${this.options.prefix}_overlay {
        display: flex;
        justify-content: center;
        font-family: sans-serif;
        font-size: 13px;
        position: absolute;
        top: 0;
        left: 0;
        width: 100vw;
        height: 100vh;
        background: rgba(0, 0, 0, 0);
        z-index: 10;
      }

      .${this.options.prefix}_modal {
        display: flex;
        justify-content: center;
        align-items: center;
        position: relative;
        top: 20px;
        width: auto;
        z-index: 101;
        opacity: 1;
        transition: all 0.2s;
        will-change: opacity, transform;
        box-shadow: 0 10px 10px rgba(0, 0, 0, 0.05);
        padding: 0 30px;
        height: 68px;
        border-radius: 100px;
        background: rgba(29, 32, 39, 0.97);
        pointer-events: auto;
      }

      .${this.options.prefix}_modal.hidden {
        opacity: 0;
        transform: translateY(-10px) scale(0.95);
      }

      .${this.options.prefix}_heading {
        font-size: 1.1em;
        font-weight: 600;
        color: rgba(255, 255, 255, 0.9);
      }

      .${this.options.prefix}_icon svg {
        stroke: #FF4D4D;
      }

      .${this.options.prefix}_content {
        margin-left: 20px;
      }

      .${this.options.prefix}_content p {
        padding: 0;
        margin: 8px 0 0;
        color: rgba(255, 255, 255, 0.5);
      }

      .${this.options.prefix}_button {
        cursor: pointer;
        margin-left: 40px;
        padding: 8px 10px;
        border: solid 1px rgba(255, 255, 255, 0.2);
        border-radius: 5px;
        font-size: 12px;
        color: rgba(255, 255, 255, 0.5);
      }

      .${this.options.prefix}_button:hover {
        border: solid 1px rgba(255, 255, 255, 0.6);
        color: rgba(255, 255, 255, 0.9);
      }
    `;

    this.online      = this.online.bind(this);
    this.offline     = this.offline.bind(this);
    this.hideMessage = this.hideMessage.bind(this);
    this.options     = this.extend(this.options, options);
    this.setup();
  }

  // extend object with another objects
  extend(destination, source) {
    if (source) {
      for (let property in source) {
        if (source[property] && source[property].constructor && (source[property].constructor === Object)) {
          destination[property] = destination[property] || {};
          arguments.callee(destination[property], source[property]);
        } else {
          destination[property] = source[property];
        }
      }
    }
    return destination
  }

  setup(){
    this.events = {
      fields:  ["keyup", "change"],
      network: ["online", "offline"]
    };

    this.elements = {
      fields:  document.querySelectorAll(this.options.fields),
      overlay: document.createElement("div"),
      modal:   document.createElement("div"),
      icon:    document.createElement("div"),
      content: document.createElement("div"),
      heading: document.createElement("strong"),
      desc:    document.createElement("p"),
      button:  document.createElement("a")
    };

    this.attachEvents();

    if (!this.noStyles){
      this.addStyles();
    }
  }

  addStyles(){
    let style = document.createElement("style");
    style.innerHTML = this.defaultStyles;

    let ref = document.querySelector("body");
    ref.parentNode.insertBefore(style, ref);
  }

  createElements(){

    // overlay
    this.newElement({
      context: document.body,
      element: "overlay",
      onCreate: (el) => {
        if (!this.options.overlay){
          el.style["pointer-events"] = "none";
        }
      }
    });

    // modal
    this.newElement({
      context: this.elements.overlay,
      element: "modal",
      className: "hidden",
      onCreate: (el) => {
        setTimeout(() => {
          el.classList.remove("hidden");
        }, 200);
      }
    });

    // icon
    this.newElement({
      context: this.elements.modal,
      element: "icon"
    });

    // content
    this.newElement({
      context: this.elements.modal,
      element: "content"
    });

    // heading
    this.newElement({
      context: this.elements.content,
      element: "heading"
    });

    // description
    this.newElement({
      context: this.elements.content,
      element: "desc"
    });

    // button
    if (!this.options.disableDismiss){
      this.newElement({
        context: this.elements.modal,
        element: "button"
      });
      this.elements.button.addEventListener("click", this.hideMessage);
    }
  }

  newElement(options){
    let el = this.elements[options.element];

    el.setAttribute("class", `${this.options.prefix}_${options.element}`);
    el = options.context.appendChild(el);

    if (options.className){
      el.classList.add(options.className);
    }

    if (this.options.text.offline[options.element]){
      el.innerHTML = this.options.text.offline[options.element];
    }

    if (options.onCreate){
      options.onCreate.call(this, el);
    }
  }

  destroyElements(){
    if (this.elements.overlay){
      this.elements.overlay.remove();
    }
  }

  attachEvents(){
    for (let field of Array.from(this.elements.fields)){
      this.elementEvents(field);
    }

    for (let event of Array.from(this.events.network)){
      this.networkEvents(event);
    }
  }

  elementEvents(field){
    Array.from(this.events.fields).map((event) =>
      field.addEventListener(event, () => {
        this.modified = true;
      })
    );
  }

  networkEvents(event){
    window.addEventListener(event, this[event]);
  }

  online(event){
    this.hideMessage();
  }

  offline(){
    if (this.options.monitorFields){
      if (this.modified){
        this.showMessage();
      }
    } else {
      this.showMessage();
    }
  }

  showMessage(){
    this.createElements();

    if (this.options.onOnline){
      this.options.onOnline.call(this);
    }
  }

  hideMessage(event){
    if (event){
      event.preventDefault();
    }

    this.destroyElements();
    if (this.options.onOffline){
      this.options.onOffline.call(this);
    }
  }
};

export default Heyoffline;
