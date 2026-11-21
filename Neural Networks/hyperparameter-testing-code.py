import os
import random
import time
import copy
import warnings
warnings.filterwarnings("ignore")

import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import seaborn as sns

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, Subset, ConcatDataset

import torchvision
import torchvision.transforms as transforms

from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (accuracy_score, f1_score,
                             confusion_matrix, classification_report)


# global config !!!

# 3 seeds so results are not just lucky initialization
SEEDS      = [42, 123, 777]
DEVICE     = torch.device("cuda" if torch.cuda.is_available() else "cpu")

DATA_DIR   = "./data"
OUT_DIR    = "./output"

BATCH_SIZE  = 256   # 256 is fast
MAX_EPOCHS  = 15
ES_PATIENCE = 3     # stop training if val loss doesn't get better for 3 epochs in a row

# known mean and std of CIFAR-10 -- used to normalize images to ~zero mean
CIFAR10_MEAN = (0.4914, 0.4822, 0.4465)
CIFAR10_STD  = (0.2470, 0.2435, 0.2616)
CLASSES      = ("plane", "car", "bird", "cat", "deer",
                "dog", "frog", "horse", "ship", "truck")

# Exp configurations
TOPOLOGIES = {
    "M1: [256]":               [256],
    "M2: [512,256]":           [512, 256],
    "M3: [1024,512,256]":      [1024, 512, 256],
    "M4: [256,128,64,32]":     [256, 128, 64, 32],
    "M5: [2048,1024,512,256]": [2048, 1024, 512, 256],
}

OPTIMIZERS = {
    "SGD(mom=0.9)": lambda m: optim.SGD(m.parameters(),     lr=0.01, momentum=0.9),
    "Adam":         lambda m: optim.Adam(m.parameters(),    lr=0.01),
    "RMSprop":      lambda m: optim.RMSprop(m.parameters(), lr=0.01, alpha=0.99),
}

LR_VALUES = [0.1, 0.01, 0.001, 0.0001, 0.00001]

ACTIVATIONS = {
    "ReLU":            nn.ReLU,
    "LeakyReLU(0.01)": lambda: nn.LeakyReLU(0.01),
    "ELU(1.0)":        lambda: nn.ELU(1.0),
    "SELU":            nn.SELU,
    "GELU":            nn.GELU,
}

REG_CONFIGS = {
    "No reg":            {"dropout": 0.0, "wd": 0.0},
    "Dropout 0.3":       {"dropout": 0.3, "wd": 0.0},
    "Dropout 0.5":       {"dropout": 0.5, "wd": 0.0},
    "L2 1e-4":           {"dropout": 0.0, "wd": 1e-4},
    "L2 1e-3":           {"dropout": 0.0, "wd": 1e-3},
    "Drop0.3 + L2 1e-4": {"dropout": 0.3, "wd": 1e-4},
}


# utilities

class EarlyStopping:
    def __init__(self, patience=5):
        self.patience = patience
        self.best_loss = float("inf")
        self.counter = 0
        self.best_weights = None

    def step(self, val_loss, model):
        # only count as improvement if dropped more than 1e-4
        if val_loss < self.best_loss - 1e-4:
            self.best_loss = val_loss
            self.counter = 0
            # save a real copy of weights
            self.best_weights = copy.deepcopy(model.state_dict())
        else:
            self.counter += 1
        return self.counter >= self.patience

    def restore(self, model):
        if self.best_weights:
            model.load_state_dict(self.best_weights)


def set_seed(seed):
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)
    # force GPU to use the same algorithm every run so results don't change
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False


def load_data():
    # Download dataset and return train/val/test splits
    print("\n[1] Loading CIFAR-10 ...")
    transform = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize(CIFAR10_MEAN, CIFAR10_STD),
    ])
    full_train = torchvision.datasets.CIFAR10(
        root=DATA_DIR, train=True, download=True, transform=transform)
    test_set = torchvision.datasets.CIFAR10(
        root=DATA_DIR, train=False, download=True, transform=transform)

    # seed before shuffle so we always get the same split
    set_seed(42)
    all_idx = list(range(len(full_train)))
    random.shuffle(all_idx)
    # 15k train + 2k val instead of all -- keep runtime faster for my laptop :)
    val_idx   = all_idx[:2000]
    train_idx = all_idx[2000:17000]

    train_set = Subset(full_train, train_idx)
    val_set   = Subset(full_train, val_idx)

    print(f"    Train: {len(train_set):,}  Val: {len(val_set):,}  Test: {len(test_set):,}")
    return train_set, val_set, test_set, full_train


def make_loaders(train_set, val_set, test_set, batch_size=BATCH_SIZE):
    # seeded generator keeps the shuffle order the same every run
    g = torch.Generator()
    g.manual_seed(42)
    train_loader = DataLoader(train_set, batch_size=batch_size,
                              shuffle=True, num_workers=0, generator=g)
    val_loader   = DataLoader(val_set,   batch_size=batch_size,
                              shuffle=False, num_workers=0)
    test_loader  = DataLoader(test_set,  batch_size=batch_size,
                              shuffle=False, num_workers=0)
    return train_loader, val_loader, test_loader


def dataset_to_numpy(ds):
    imgs, labs = [], []
    for img, label in ds:
        imgs.append(img.numpy().flatten())
        labs.append(label)
    return np.array(imgs), np.array(labs)


def build_mlp(hidden_layers, activation_cls=nn.ReLU, dropout_p=0.0):
    # return a function, not the model -- so each seed gets a freshly initialized model
    def _make():
        layers = [nn.Flatten()]  # vectorization
        in_dim = 3072
        for h in hidden_layers:
            layers.append(nn.Linear(in_dim, h))
            layers.append(activation_cls())  # activation adds non-linearity between layers
            if dropout_p > 0:
                layers.append(nn.Dropout(dropout_p))  # randomly turn off some neurons to reduce overfitting
            in_dim = h
        layers.append(nn.Linear(in_dim, 10))  # 10 outputs, one score per class
        return nn.Sequential(*layers)
    return _make


def train_one_epoch(model, loader, criterion, optimizer):
    model.train()
    total_loss, correct, n = 0.0, 0, 0
    for xb, yb in loader:
        xb, yb = xb.to(DEVICE), yb.to(DEVICE)
        optimizer.zero_grad()  # clear old gradients before each batch
        out  = model(xb)
        loss = criterion(out, yb)
        loss.backward()        # calculate gradients
        optimizer.step()       # update weights
        total_loss += loss.item() * len(yb)
        correct    += (out.argmax(1) == yb).sum().item()
        n          += len(yb)
    return total_loss / n, correct / n


def evaluate(model, loader, criterion):
    model.eval()
    total_loss, correct, n = 0.0, 0, 0
    with torch.no_grad():  # no need to track gradients, saves memory
        for xb, yb in loader:
            xb, yb = xb.to(DEVICE), yb.to(DEVICE)
            out  = model(xb)
            loss = criterion(out, yb)
            total_loss += loss.item() * len(yb)
            correct    += (out.argmax(1) == yb).sum().item()
            n          += len(yb)
    return total_loss / n, correct / n # (mean_loss, accuracy)


def run_experiment(model_fn, optimizer_fn, seed,
                   train_ldr, val_ldr,
                   max_epochs=MAX_EPOCHS, patience=ES_PATIENCE):
    # train model with one seed, return best_val_acc, train_losses, val_losses, epochs, elapsed, model
    set_seed(seed)
    model     = model_fn().to(DEVICE)
    optimizer = optimizer_fn(model)
    criterion = nn.CrossEntropyLoss()
    es        = EarlyStopping(patience)

    train_losses, val_losses = [], []
    t0 = time.time()
    for epoch in range(1, max_epochs + 1):
        tl, _  = train_one_epoch(model, train_ldr, criterion, optimizer)
        vl, _  = evaluate(model, val_ldr, criterion)
        train_losses.append(tl)
        val_losses.append(vl)
        if es.step(vl, model):
            break

    es.restore(model)
    _, best_va = evaluate(model, val_ldr, criterion)
    return best_va, train_losses, val_losses, len(train_losses), time.time() - t0, model


def multi_seed_run(model_fn, optimizer_fn, label, train_ldr, val_ldr):
    # Run model with all seeds
    accs, best_curves, best_acc = [], None, -1
    for seed in SEEDS:
        va, tl, vl, ep, elapsed, _ = run_experiment(
            model_fn, optimizer_fn, seed, train_ldr, val_ldr)
        accs.append(va)
        print(f"      seed={seed}  val_acc={va:.4f}  epochs={ep}  time={elapsed:.0f}s")
        if va > best_acc:
            best_acc    = va
            best_curves = (tl, vl)
    mean, std = float(np.mean(accs)), float(np.std(accs))
    print(f"    {label}  mean={mean:.4f}  std={std:.4f}")
    return mean, std, best_curves


# helper for plots

def plot_curves(curves, title, out_path, legend_fontsize=8):
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))
    for name, (tl, vl) in curves.items():
        axes[0].plot(tl, label=name)
        axes[1].plot(vl, label=name)
    axes[0].set_title(f"Train loss – {title}")
    axes[0].set_xlabel("Epoch")
    axes[0].legend(fontsize=legend_fontsize)
    axes[1].set_title(f"Val loss – {title}")
    axes[1].set_xlabel("Epoch")
    axes[1].legend(fontsize=legend_fontsize)
    plt.tight_layout()
    plt.savefig(out_path, dpi=120)
    plt.close()


def plot_confusion(cm, classes, title, out_path):
    # Save a confusion matrix
    fig, ax = plt.subplots(figsize=(8, 7))
    sns.heatmap(cm, annot=True, fmt="d", cmap="Blues",
                xticklabels=classes, yticklabels=classes, ax=ax)
    ax.set_title(title)
    ax.set_ylabel("True")
    ax.set_xlabel("Predicted")
    plt.tight_layout()
    plt.savefig(out_path, dpi=120)
    plt.close()


# [2] EDA

def run_eda(full_train, train_set, val_set, out_dir):
    print("\n[2] EDA ...")

    train_idx = train_set.indices
    val_idx   = val_set.indices

    # Class distribution
    all_labels = ([full_train.targets[i] for i in train_idx] +
                  [full_train.targets[i] for i in val_idx])
    counts = pd.Series(all_labels).value_counts().sort_index()
    fig, ax = plt.subplots(figsize=(8, 4))
    ax.bar([CLASSES[i] for i in counts.index], counts.values,
           color="steelblue", edgecolor="white")
    ax.set_title("Class distribution (train + validation)")
    ax.set_ylabel("Count")
    ax.set_xlabel("Class")
    plt.tight_layout()
    plt.savefig(f"{out_dir}/eda_class_distribution.png", dpi=120)
    plt.close()

    # One sample per class
    fig, axes = plt.subplots(2, 5, figsize=(12, 5))
    shown = {c: False for c in range(10)}
    for img, label in full_train:
        if not shown[label]:
            r, c = label // 5, label % 5
            img_np = np.clip(
                img.numpy().transpose(1, 2, 0) * np.array(CIFAR10_STD) + np.array(CIFAR10_MEAN),
                0, 1)
            axes[r, c].imshow(img_np)
            axes[r, c].set_title(CLASSES[label])
            axes[r, c].axis("off")
            shown[label] = True
        if all(shown.values()):
            break
    plt.suptitle("One sample per class")
    plt.tight_layout()
    plt.savefig(f"{out_dir}/eda_sample_images.png", dpi=120)
    plt.close()

    # Pixel histogram
    subset_imgs = np.array([full_train[i][0].numpy() for i in train_idx[:5000]])
    ch_mean = subset_imgs.mean(axis=(0, 2, 3))
    ch_std  = subset_imgs.std(axis=(0, 2, 3))
    print(f"    mean(R,G,B): {ch_mean[0]:.3f}, {ch_mean[1]:.3f}, {ch_mean[2]:.3f}")
    print(f"    std (R,G,B): {ch_std[0]:.3f},  {ch_std[1]:.3f},  {ch_std[2]:.3f}")
    fig, ax = plt.subplots(figsize=(8, 4))
    for c, col in enumerate(["red", "green", "blue"]):
        ax.hist(subset_imgs[:, c].flatten(), bins=60, alpha=0.5,
                color=col, label=["R", "G", "B"][c], density=True)
    ax.set_title("Pixel value distribution per channel")
    ax.legend()
    plt.tight_layout()
    plt.savefig(f"{out_dir}/eda_pixel_histogram.png", dpi=120)
    plt.close()

    print("EDA plots saved.")


# [3] BASELINE

def run_baseline(train_set, val_set, test_set, out_dir):
    # training of baseline model
    print("\n[3] Baseline – Logistic Regression ...")

    X_tr, y_tr = dataset_to_numpy(train_set)
    X_vl, y_vl = dataset_to_numpy(val_set)
    X_te, y_te = dataset_to_numpy(test_set)

    set_seed(42)
    clf = LogisticRegression(max_iter=1000, C=1.0, solver="lbfgs",
                             random_state=42, n_jobs=-1)
    t0 = time.time()
    clf.fit(X_tr, y_tr)
    print(f"    Trained in {time.time() - t0:.1f}s")

    val_acc  = accuracy_score(y_vl, clf.predict(X_vl))
    test_acc = accuracy_score(y_te, clf.predict(X_te))
    test_f1  = f1_score(y_te, clf.predict(X_te), average="macro")
    print(f"    Val acc={val_acc:.4f}  Test acc={test_acc:.4f}  Test F1={test_f1:.4f}")
    print(classification_report(y_te, clf.predict(X_te), target_names=CLASSES))

    cm = confusion_matrix(y_te, clf.predict(X_te))
    plot_confusion(cm, CLASSES,
                   f"Baseline LogReg (test acc={test_acc:.4f})",
                   f"{out_dir}/baseline_confusion_matrix.png")

    return {"val_acc": val_acc, "test_acc": test_acc, "test_f1": test_f1}


# [4] exp 1 – tolology

def run_exp1_topology(train_loader, val_loader, out_dir):
    print("\n[4] Experiment 1 – Topologies ...")

    def sgd_fixed(m):
        return optim.SGD(m.parameters(), lr=0.01, momentum=0.9)

    topo_results = {}
    curves = {}
    for name, layers in TOPOLOGIES.items():
        print(f"  {name}")
        mean, std, (tl, vl) = multi_seed_run(
            build_mlp(layers), sgd_fixed, name, train_loader, val_loader)
        topo_results[name] = {"mean": mean, "std": std}
        curves[name] = (tl, vl)

    plot_curves(curves, "Topologies", f"{out_dir}/exp1_topologies.png",
                legend_fontsize=7)

    best_name = max(topo_results, key=lambda k: topo_results[k]["mean"])
    print(f"\n  >>> Best topology: {best_name}"
          f"  (mean val acc={topo_results[best_name]['mean']:.4f})")

    return best_name, TOPOLOGIES[best_name], topo_results


# [5] exp 2 – optimizer

def run_exp2_optimizer(best_topo_layers, train_loader, val_loader, out_dir):
    print("\n[5] Experiment 2 – Optimizers ...")

    optim_results = {}
    curves = {}
    for name, opt_fn in OPTIMIZERS.items():
        print(f"  {name}")
        mean, std, (tl, vl) = multi_seed_run(
            build_mlp(best_topo_layers), opt_fn, name, train_loader, val_loader)
        optim_results[name] = {"mean": mean, "std": std}
        curves[name] = (tl, vl)

    plot_curves(curves, "Optimizers", f"{out_dir}/exp2_optimizers.png")

    best_name   = max(optim_results, key=lambda k: optim_results[k]["mean"])
    best_opt_fn = OPTIMIZERS[best_name]
    # get the optimizer class so later experiments can use it with a different lr
    opt_base    = type(best_opt_fn(build_mlp(best_topo_layers)()))
    print(f"\n  >>> Best optimizer: {best_name}"
          f"  (mean val acc={optim_results[best_name]['mean']:.4f})")

    return best_name, best_opt_fn, opt_base, optim_results


# [6] exp 3 – LR

def run_exp3_lr(best_topo_layers, opt_base, train_loader, val_loader, out_dir):
    print("\n[6] Experiment 3 – Learning rates ...")

    lr_results = {}
    curves = {}
    for lr in LR_VALUES:
        label = f"lr={lr}"
        print(f"  {label}")

        def make_opt(lr=lr):
            def _fn(m): return opt_base(m.parameters(), lr=lr)
            return _fn

        mean, std, (tl, vl) = multi_seed_run(
            build_mlp(best_topo_layers), make_opt(lr), label, train_loader, val_loader)
        lr_results[label] = {"lr": lr, "mean": mean, "std": std}
        curves[label] = (tl, vl)

    plot_curves(curves, "LR", f"{out_dir}/exp3_learning_rates.png")

    best_key = max(lr_results, key=lambda k: lr_results[k]["mean"])
    best_lr  = lr_results[best_key]["lr"]
    print(f"\n  >>> Best LR: {best_lr}"
          f"  (mean val acc={lr_results[best_key]['mean']:.4f})")

    def best_opt_fn(m):
        return opt_base(m.parameters(), lr=best_lr)

    return best_key, best_lr, best_opt_fn, lr_results


# [7] exp 4 – activation functions

def run_exp4_activation(best_topo_layers, best_opt_fn, train_loader, val_loader, out_dir):
    """return best name, best act class, and results dict"""
    print("\n[7] Experiment 4 – Activation functions ...")

    act_results = {}
    curves = {}
    for name, act_cls in ACTIVATIONS.items():
        print(f"  {name}")
        mean, std, (tl, vl) = multi_seed_run(
            build_mlp(best_topo_layers, activation_cls=act_cls),
            best_opt_fn, name, train_loader, val_loader)
        act_results[name] = {"mean": mean, "std": std}
        curves[name] = (tl, vl)

    plot_curves(curves, "Activations", f"{out_dir}/exp4_activations.png")

    best_name    = max(act_results, key=lambda k: act_results[k]["mean"])
    best_act_cls = ACTIVATIONS[best_name]
    print(f"\n  >>> Best activation: {best_name}"
          f"  (mean val acc={act_results[best_name]['mean']:.4f})")

    return best_name, best_act_cls, act_results


# [8] exp 5 – regularization

def run_exp5_regularization(best_topo_layers, best_act_cls, best_lr, opt_base, train_loader, val_loader, out_dir):
    print("\n[8] Experiment 5 – Regularization ...")

    reg_results = {}
    curves = {}
    for name, cfg in REG_CONFIGS.items():
        print(f"  {name}")
        dp, wd = cfg["dropout"], cfg["wd"]

        def make_reg_opt(wd=wd):
            def _fn(m): return opt_base(m.parameters(), lr=best_lr, weight_decay=wd)
            return _fn

        mean, std, (tl, vl) = multi_seed_run(
            build_mlp(best_topo_layers, activation_cls=best_act_cls, dropout_p=dp),
            make_reg_opt(wd), name, train_loader, val_loader)
        reg_results[name] = {"mean": mean, "std": std}
        curves[name] = (tl, vl)

    plot_curves(curves, "Regularization", f"{out_dir}/exp5_regularization.png",
                legend_fontsize=8)

    best_name = max(reg_results, key=lambda k: reg_results[k]["mean"])
    print(f"\n  >>> Best regularization: {best_name}"
          f"  (mean val acc={reg_results[best_name]['mean']:.4f})")

    return best_name, REG_CONFIGS[best_name], reg_results


# [9] final model

def run_final_model(best_topo_layers, best_act_cls, best_reg_cfg,
                    best_lr, opt_base,
                    train_set, val_set, val_loader, test_loader, out_dir):
    #Train final model on train+val
    print("\n[9] Final model ...")

    # val was only for picking hyperparameters, now we don't need it separate
    # so merge train+val together to give the model more data
    full_trainval = ConcatDataset([train_set, val_set])
    g_final = torch.Generator()
    g_final.manual_seed(42)
    final_train_loader = DataLoader(full_trainval, batch_size=BATCH_SIZE,
                                    shuffle=True, num_workers=0, generator=g_final)

    set_seed(42)
    model = build_mlp(
        best_topo_layers,
        activation_cls=best_act_cls,
        dropout_p=best_reg_cfg["dropout"],
    )().to(DEVICE)

    optimizer = opt_base(model.parameters(),
                         lr=best_lr, weight_decay=best_reg_cfg["wd"])
    criterion = nn.CrossEntropyLoss()
    es        = EarlyStopping(patience=ES_PATIENCE)

    for epoch in range(1, MAX_EPOCHS + 1):
        tl, _  = train_one_epoch(model, final_train_loader, criterion, optimizer)
        vl, va = evaluate(model, val_loader, criterion)
        if epoch % 5 == 0:
            print(f"    epoch {epoch:2d}  train_loss={tl:.4f}  val_acc={va:.4f}")
        if es.step(vl, model):
            print(f"    Early stop at epoch {epoch}")
            break

    es.restore(model)
    _, test_acc = evaluate(model, test_loader, criterion)

    all_preds, all_true = [], []
    model.eval()
    with torch.no_grad():
        for xb, yb in test_loader:
            xb = xb.to(DEVICE)
            all_preds.extend(model(xb).argmax(1).cpu().numpy())
            all_true.extend(yb.numpy())

    test_f1 = f1_score(all_true, all_preds, average="macro")
    print(f"\n  Final Test Accuracy : {test_acc:.4f}")
    print(f"  Final Test F1 (macro): {test_f1:.4f}")
    print(classification_report(all_true, all_preds, target_names=CLASSES))

    cm = confusion_matrix(all_true, all_preds)
    plot_confusion(cm, CLASSES,
                   f"Final Model – test acc={test_acc:.4f}",
                   f"{out_dir}/final_confusion_matrix.png")

    torch.save(model.state_dict(), f"{out_dir}/best_model.pth")

    return {"test_acc": test_acc, "test_f1": test_f1}


# [10] summary

def print_summary(all_results, best):
    print("\n" + "=" * 70)
    print("RESULTS SUMMARY")
    print("=" * 70)

    bl = all_results["baseline"]
    print(f"\nBaseline (Logistic Regression): val={bl['val_acc']:.4f}  test={bl['test_acc']:.4f}")

    print("\nExp 1 – Topologies (val acc mean ± std):")
    for k, v in all_results["exp1"].items():
        marker = " <-- BEST" if k == best["topo_name"] else ""
        print(f"  {k:<40s}  {v['mean']:.4f} ± {v['std']:.4f}{marker}")

    print("\nExp 2 – Optimizers (val acc mean ± std):")
    for k, v in all_results["exp2"].items():
        marker = " <-- BEST" if k == best["opt_name"] else ""
        print(f"  {k:<20s}  {v['mean']:.4f} ± {v['std']:.4f}{marker}")

    print("\nExp 3 – Learning Rates (val acc mean ± std):")
    for k, v in all_results["exp3"].items():
        marker = " <-- BEST" if k == best["lr_key"] else ""
        print(f"  {k:<15s}  {v['mean']:.4f} ± {v['std']:.4f}{marker}")

    print("\nExp 4 – Activations (val acc mean ± std):")
    for k, v in all_results["exp4"].items():
        marker = " <-- BEST" if k == best["act_name"] else ""
        print(f"  {k:<20s}  {v['mean']:.4f} ± {v['std']:.4f}{marker}")

    print("\nExp 5 – Regularization (val acc mean ± std):")
    for k, v in all_results["exp5"].items():
        marker = " <-- BEST" if k == best["reg_name"] else ""
        print(f"  {k:<25s}  {v['mean']:.4f} ± {v['std']:.4f}{marker}")

    final = all_results["final"]
    print(f"\nFinal Model Config:")
    print(f"  Topology   : {best['topo_name']}")
    print(f"  Optimizer  : {best['opt_name']}  lr={best['lr']}")
    print(f"  Activation : {best['act_name']}")
    print(f"  Regulariz. : {best['reg_name']}")
    print(f"  Test Acc   : {final['test_acc']:.4f}")
    print(f"  Test F1    : {final['test_f1']:.4f}")
    print("\nAll plots saved to ./output/")
    print("Model saved to ./output/best_model.pth")


# all packed in main, all testing process here

def main():
    print(f"[0] Device: {DEVICE}")
    os.makedirs(OUT_DIR, exist_ok=True)

    # Data
    train_set, val_set, test_set, full_train = load_data()
    train_loader, val_loader, test_loader = make_loaders(train_set, val_set, test_set)

    # EDA + Baseline
    run_eda(full_train, train_set, val_set, OUT_DIR)
    baseline_res = run_baseline(train_set, val_set, test_set, OUT_DIR)

    # hyperparameter experiments
    best_topo_name, best_topo_layers, exp1_res = run_exp1_topology(
        train_loader, val_loader, OUT_DIR)

    best_opt_name, _, opt_base, exp2_res = run_exp2_optimizer(
        best_topo_layers, train_loader, val_loader, OUT_DIR)

    best_lr_key, best_lr, best_opt_fn, exp3_res = run_exp3_lr(
        best_topo_layers, opt_base, train_loader, val_loader, OUT_DIR)

    best_act_name, best_act_cls, exp4_res = run_exp4_activation(
        best_topo_layers, best_opt_fn, train_loader, val_loader, OUT_DIR)

    best_reg_name, best_reg_cfg, exp5_res = run_exp5_regularization(
        best_topo_layers, best_act_cls, best_lr, opt_base,
        train_loader, val_loader, OUT_DIR)

    # Final model
    final_res = run_final_model(
        best_topo_layers, best_act_cls, best_reg_cfg,
        best_lr, opt_base,
        train_set, val_set, val_loader, test_loader, OUT_DIR)

    # Summary
    all_results = {
        "baseline": baseline_res,
        "exp1": exp1_res,
        "exp2": exp2_res,
        "exp3": exp3_res,
        "exp4": exp4_res,
        "exp5": exp5_res,
        "final": final_res,
    }
    best = {
        "topo_name": best_topo_name,
        "opt_name":  best_opt_name,
        "lr_key":    best_lr_key,
        "lr":        best_lr,
        "act_name":  best_act_name,
        "reg_name":  best_reg_name,
    }
    print_summary(all_results, best)


if __name__ == "__main__":
    main()
